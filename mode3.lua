function courseplay:handleMode3(vehicle, fillLevelPct, allowedToDrive, dt)
	courseplay:debug(string.format("handleMode3(vehicle, fillLevelPct=%s, allowedToDrive=%s, dt)", tostring(fillLevelPct), tostring(allowedToDrive)), 15);
	local workTool = vehicle.tippers[vehicle.cp.currentTrailerToFill] or vehicle.tippers[1];
	local backPointsUnfoldPipe = 8; --[[workTool.cp.backPointsUnfoldPipe or 8;]] --NOTE: backPointsUnfoldPipe must not be 0! 
	local forwardPointsFoldPipe = workTool.cp.forwardPointsFoldPipe or 2;
	workTool.cp.isUnloading = workTool.fillLevel < workTool.cp.lastFillLevel;

	if workTool.cp.isAugerWagon then
		if vehicle.wait and vehicle.cp.lastRecordnumber >= math.max(vehicle.cp.waitPoints[1] - backPointsUnfoldPipe, 2) and vehicle.cp.lastRecordnumber < vehicle.cp.waitPoints[1] and not workTool.cp.isUnloading then
			courseplay:handleAugerWagon(vehicle, workTool, true, false, "unfold"); --unfold=true, unload=false
		end;

		if vehicle.wait and vehicle.cp.lastRecordnumber == vehicle.cp.waitPoints[1] then
			courseplay:setGlobalInfoText(vehicle, 'OVERLOADING_POINT');

			local driveOn = false
			if fillLevelPct > 0 then
				courseplay:handleAugerWagon(vehicle, workTool, true, true, "unload"); --unfold=true, unload=true
			end;
			if vehicle.cp.prevFillLevelPct ~= nil then
				if fillLevelPct > 0 and workTool.cp.isUnloading then
					courseplay:setCustomTimer(vehicle, "fillLevelChange", 7);
				elseif fillLevelPct == vehicle.cp.prevFillLevelPct and fillLevelPct < vehicle.cp.followAtFillLevel and courseplay:timerIsThrough(vehicle, "fillLevelChange", false) then
					driveOn = true; -- drive on if fillLevelPct doesn't change for 7 seconds and fill level is < required_fillLevelPct_for_follow
				end;
			end;

			vehicle.cp.prevFillLevelPct = fillLevelPct;

			if (fillLevelPct == 0 or driveOn) and not workTool.cp.isUnloading then
				courseplay:handleAugerWagon(vehicle, workTool, true, false, "stopUnload"); --unfold=true, unload=false
				vehicle.cp.prevFillLevelPct = nil;
				courseplay:cancelWait(vehicle);
			end;
		end;

		if courseplay.debugChannels[15] then
			courseplay:checkAndPrintChange(vehicle, vehicle.cp.waitPoints[1], "firstWaitPoint");
			courseplay:checkAndPrintChange(vehicle, vehicle.maxnumber, "maxnumber");
			courseplay:checkAndPrintChange(vehicle, backPointsUnfoldPipe, "backPointsUnfoldPipe");
			courseplay:checkAndPrintChange(vehicle, forwardPointsFoldPipe, "forwardPointsFoldPipe");

			courseplay:checkAndPrintChange(vehicle, vehicle.cp.lastRecordnumber, "lastRecordnumber");
			courseplay:checkAndPrintChange(vehicle, vehicle.cp.isUnloaded, "isUnloaded");
			courseplay:checkAndPrintChange(vehicle, vehicle.wait, "wait");
			print("-------------------------");
		end;

		if vehicle.cp.lastRecordnumber < math.max(vehicle.cp.waitPoints[1] - backPointsUnfoldPipe, 2) then -- is before unfold pipe point
			courseplay:handleAugerWagon(vehicle, workTool, false, false, "foldBefore"); --unfold=false, unload=false
		elseif (not vehicle.wait or vehicle.cp.isUnloaded) and vehicle.cp.lastRecordnumber >= math.min(vehicle.cp.waitPoints[1] + forwardPointsFoldPipe, vehicle.maxnumber - 1) then -- is past fold pipe point
			courseplay:handleAugerWagon(vehicle, workTool, false, false, "foldAfter"); --unfold=false, unload=false
		elseif workTool.cp.isUnloading and not vehicle.wait then
			courseplay:handleAugerWagon(vehicle, workTool, true, false, "forceStopUnload"); --unfold=true, unload=false
		end;
	end;

	workTool.cp.lastFillLevel = workTool.fillLevel;
end;



function courseplay:handleAugerWagon(vehicle, workTool, unfold, unload, orderName)
	courseplay:debug(string.format("\thandleAugerWagon(vehicle, %s, unfold=%s, unload=%s, orderName=%s)", nameNum(workTool), tostring(unfold), tostring(unload), tostring(orderName)), 15);
	local pipeOrderExists = unfold ~= nil;
	local unloadOrderExists = unload ~= nil;

	--Taarup Shuttle
	if workTool.cp.isTaarupShuttle then
		if pipeOrderExists then
			if unfold and workTool.animationParts[1].clipStartTime then
				workTool:setAnimationTime(1, workTool.animationParts[1].animDuration, false);
			elseif not unfold and workTool.animationParts[1].clipEndTime then
				workTool:setAnimationTime(1, workTool.animationParts[1].offSet, false);
			end;
		end;

		if unloadOrderExists then
			if (unload and workTool.unloadingState ~= 1) or (not unload and workTool.unloadingState ~= 0) then
				workTool:setUnloadingState(unload);
			end;
		end;

	--Overcharge / AgrolinerTUW20 / Hawe SUW
	elseif workTool.cp.hasSpecializationOvercharge or workTool.cp.hasSpecializationAgrolinerTUW20 or workTool.cp.hasSpecializationHaweSUW then
		if pipeOrderExists then
			if unfold and not workTool.pipe.out then
				workTool:setAnimationTime(1, workTool.animationParts[1].animDuration, false);
				if workTool.cp.hasPipeLight and workTool.cp.pipeLight.a ~= courseplay.lightsNeeded then
					workTool:setState("work:1", courseplay.lightsNeeded);
				end;
			elseif not unfold and workTool.pipe.out then
				workTool:setAnimationTime(1, workTool.animationParts[1].offSet, false);
				if workTool.cp.hasPipeLight and workTool.cp.pipeLight.a then
					workTool:setState("work:1", false);
				end;
			end;
		end;

		if unload and not workTool.isUnloading and workTool.trailerFoundId ~= 0 then
			workTool:setUnloadingState(true);
			if workTool.isDrumActivated ~= nil then
				workTool.isDrumActivated = workTool.isUnloading;
			end;
		elseif not unload and workTool.isUnloading then
			workTool:setUnloadingState(false);
			if workTool.isDrumActivated ~= nil then
				workTool.isDrumActivated = workTool.isUnloading;
			end;
		end;

	--Ropa Big Bear / 'bigBear' spec
	elseif workTool.cp.hasSpecializationBigBear then
		if pipeOrderExists then
			if unfold and not workTool.activeWorkMode then
				if not workTool.workMode then
					courseplay:debug('\t\tunfold=true, activeWorkMode=false, workMode=false -> set workMode to true', 15);
					workTool.workMode = true;
					workTool.bigBearNeedEvent = true;
				else
					courseplay:debug('\t\tunfold=true, activeWorkMode=false, workMode=true -> set activeWorkMode to true', 15);
					workTool.activeWorkMode = true;
					workTool.bigBearNeedEvent = true;
				end;
			elseif not unfold then
				if workTool.activeWorkMode then
					courseplay:debug('\t\tunfold=false, activeWorkMode=true -> set activeWorkMode to false', 15);
					workTool.activeWorkMode = false;
					workTool.bigBearNeedEvent = true;
				end;
			end;
		end;

		if unload and workTool.allowOverload and not workTool.isUnloading and workTool.trailerRaycastFound then
			courseplay:debug('\t\tunload=true, allowOverload=true, isUnloading=false, trailerRaycastFound=true -> set isUnloading to true', 15);
			workTool.isUnloading = true;
			workTool.bigBearNeedEvent = true;
		elseif workTool.isUnloading and (not unload or not workTool.trailerRaycastFound or not workTool.allowOverload) then
			courseplay:debug(string.format('\t\tunload=%s, isUnloading=true, allowOverload=%s, trailerRaycastFound=%s -> set isUnloading to false', tostring(unload), tostring(workTool.allowOverload), tostring(workTool.trailerRaycastFound)), 15);
			workTool.isUnloading = false;
			workTool.bigBearNeedEvent = true;
		end;

	--Brent Avalanche
	elseif workTool.cp.isBrentAvalanche then
		-- n/a in FS13

	--Overloader spec
	elseif workTool.cp.hasSpecializationOverloaderV2 then
		if pipeOrderExists then
			if (unfold and workTool.cpAI ~= "out") or (not unfold and workTool.cpAI ~= "in") then
				local newPipeState = unfold and 'out' or 'in';
				courseplay:debug(string.format('\t\tunfold=%s, workTool.cpAI=%s -> set workTool.cpAI to %s', tostring(unfold), tostring(workTool.cpAI), newPipeState), 15);
				workTool.cpAI = newPipeState;

				if workTool.pipeLight ~= nil and getVisibility(workTool.pipeLight) ~= (unfold and courseplay.lightsNeeded) then
					if workTool.togglePipeLight then
						workTool:togglePipeLight(unfold and courseplay.lightsNeeded);
					else
						setVisibility(workTool.pipeLight, unfold and courseplay.lightsNeeded);
					end;
				end;
			end;
		end;

		local hasTrailer = workTool.trailerToOverload ~= nil;
		local trailerIsFull = hasTrailer and workTool.trailerToOverload.fillLevel and workTool.trailerToOverload.capacity and workTool.trailerToOverload.fillLevel >= workTool.trailerToOverload.capacity;
		if (unload and hasTrailer and not trailerIsFull and not workTool.isCharging) or (not unload and workTool.isCharging) then
			workTool.isCharging = unload;
			courseplay:debug(string.format('\t\tset workTool.isCharging to %s', tostring(unload)), 15);
		end;

	--AugerWagon spec
	elseif workTool.cp.hasSpecializationAugerWagon and workTool.foldAnimTime ~= nil and workTool.turnOnFoldDirection ~= nil then
		if pipeOrderExists then
			local pipeIsFolding = workTool.foldAnimTime > workTool.cp.lastFoldAnimTime;
			local pipeIsUnfolding = workTool.foldAnimTime < workTool.cp.lastFoldAnimTime;
			local pipeIsFolded = workTool.foldAnimTime == 1;
			local pipeIsUnfolded = workTool.foldAnimTime == 0;
			courseplay:debug(string.format("\t\tfoldAnimTime=%s, lastFoldAnimTime=%s", tostring(workTool.foldAnimTime), tostring(workTool.cp.lastFoldAnimTime)), 15);
			courseplay:debug(string.format("\t\tpipeIsFolding=%s, pipeIsUnfolding=%s, pipeIsFolded=%s, pipeIsUnfolded=%s", tostring(pipeIsFolding), tostring(pipeIsUnfolding), tostring(pipeIsFolded), tostring(pipeIsUnfolded)), 15);
			if unfold and not pipeIsUnfolded and not pipeIsUnfolding then
				workTool:setFoldDirection(workTool.turnOnFoldDirection); -- -1
				courseplay:debug(string.format("\t\t\tsetFoldDirection(%s) (unfold)", tostring(workTool.turnOnFoldDirection)), 15);
			elseif not unfold and not pipeIsFolded and not pipeIsFolding then
				workTool:setFoldDirection(workTool.turnOnFoldDirection * -1); -- 1
				courseplay:debug(string.format("\t\t\tsetFoldDirection(%s) (fold)", tostring(workTool.turnOnFoldDirection * -1)), 15);
			end;
			workTool.cp.lastFoldAnimTime = workTool.foldAnimTime;
		end;
	end;
end;