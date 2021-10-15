global theObject= $
global nbParts = 5
	
		
   rollout generateBox"Generate Box" --define a rollout
		(
			
		struct myFunc 
		(
			
			fn removeRandomEdges =
			(
					theObject = $
					theObject = convertToPoly (theObject)
					local amtOfEdges
					amtOfEdges = polyOp.getNumEdges theObject                 --the number of edges in the poly. Includes any dead edges.
					local edgesToDelete = amtOfEdges/5                            --1/5 of the edges to be removed
					local randomEdge
				
					for i = 1 to edgesToDelete do                                    --loop picking random edges to delete
						(
							amtOfEdges = polyOp.getNumEdges theObject
							select theObject
							max modify mode                                            
							subObjectLevel = 2
							randomEdge = random 1 amtOfEdges            
							$.EditablePoly.SetSelection #Edge #{randomEdge}       --set the selection in the specified sub-object level
							$.EditablePoly.Remove ()                                          --remove edges
						)
			),
				
				
		
			fn fragmentation =
			(			
					
					global theMesh = editable_mesh()
					global thePlane = plane width:1 length:1 widthSegs:1 lengthSegs:1	-- plane helper for slice plane
					global aPartsStart = #()
					global aPartsEnd = #()
					global aAllParts = #()
					global aAllPartsCopy = #()
					global aAllCoords = #()
					global nbIter = 1
				
				theObject = $
			-- clean copy (no custom attributes, keyframes, weird transforms, etc
					theCopy = copy theObject
					theCopy.name = "desi"
					resetXForm theCopy
					convertToMesh theCopy
					theMesh.mesh = theCopy.mesh
					theMesh.transform = theCopy.transform
					theMesh.pivot = [0,0,0]
					resetXForm theMesh
					convertToMesh theMesh
					delete theCopy
			
		-- parts creation
					aPartsEnd = #(theMesh)
					for iter = 1 to 1 do
						(
							aPartsStart = aPartsEnd
							aPartsEnd = #()
							
							for theObject in aPartsStart do
									(	
										aPartsTemp = for i = 1 to nbParts collect copy theObject
										pSys = pcloud emitter:theObject formation:3 total_number:nbParts quantityMethod:1 viewPercent:100 seed:(random 0 100)
										aCoords = for i = 1 to nbParts collect particlePos pSys i	-- fill with random coordinates
										delete pSys
										for i = 1 to nbParts - 1 do for j = i + 1 to nbParts  do	-- for each pair of coords
												(
													thePlane.pos = (aCoords[i] + aCoords[j]) / 2
													thePlane.dir = aCoords[j] - aCoords[i]
													
													addModifier aPartsTemp[i] (sliceModifier slice_type:2)
													addModifier aPartsTemp[j] (sliceModifier slice_type:3)
													aPartsTemp[i].slice.slice_plane.transform = thePlane.transform
													aPartsTemp[j].slice.slice_plane.transform = thePlane.transform
													addModifier aPartsTemp[i] (cap_holes())
													addModifier aPartsTemp[j] (cap_holes())
													convertToMesh aPartsTemp[i]
													convertToMesh aPartsTemp[j]
													
												)	-- end i loop
										aPartsEnd += aPartsTemp
										aAllParts += aPartsTemp
										aAllCoords += aCoords
										
										total = nbParts * ((nbParts^nbIter - 1) / (nbParts - 1))
									)	-- end theObject loop
						)	-- end iter loop
					for theObject in aAllParts do theObject.wireColor = random black white
					delete theObject   --st box
					delete thePlane    -- helper plane
					delete theMesh     --thelastcopy
					
					for obj in aAllParts do convertTo obj Editable_Poly      --conv the parts to edit poly
					
			),
			
				
			fn generateForm = -- this is the inset and surfsubdivision
			(
						total = aAllParts.count
						for i = 2 to total do
							(
								polyop.attach aAllParts[1] aAllParts[i] -- chooses the first object and attaches it to the next 
							)
					
						aAllPartsCopy = copy aAllParts[1]
						
						numfaces = polyop.getnumfaces aAllParts[1] 
					
						select aAllParts[1] --select the object
						max modify mode --go to modify panel
						subobjectlevel = 4 --go to polygon sub-object level
						polyop.setfaceselection aAllParts[1] #{1..numfaces}	
						aAllParts[1].insetType = 1 --insets by polygon
						aAllParts[1].insetAmount = 1.5  --inset amount
						aAllParts[1].ButtonOp #inset --grow the selection 
								
								
						polyop.setfaceselection aAllParts[1] #{1..numfaces} --selects all faces
						delete aAllParts[1].selectedfaces --deletes faces
						select aAllParts[1] 
						aAllParts[1].surfSubdivide = on --nurms subdivision
						aAllParts[1].iterations = 3
						
						select aAllPartsCopy
						actionMan.executeAction 0 "223"  --hide
			),
		
		
			fn generatePebbles =
			(			
						actionMan.executeAction 0 "277"  --unhide all
						select aAllParts[1]
						actionMan.executeAction 0 "223"  --hide
					
						
						aAllPartsCopy.surfSubdivide = on --nurms subdivision
						aAllPartsCopy.iterations = 3
			)
		
		)
			
					pickButton selectObject "Select Object" width:140 align:#center
					edittext selectObject_tf "Object: " text:"NONE" readonly:true width:138
					button randomEdges_btn "Random Edges" width:140 align:#center enabled:false
					spinner nbParts_spinner "No Fragments: " range:[1,20,nbParts] type:#integer width:140 align:#center enabled:false
					button fragmentation_btn "Fragment Object" width:140 align:#center enabled:false
					button generateForm_btn "Generate Form" width:140 align:#center enabled:false
					button generatePebbles_btn "Generate Pebbles" width:140 align:#center enabled:false
			
					on selectObject picked obj do
						(
							selectObject_tf.text = obj.name
							randomEdges_btn.enabled = true
							nbParts_spinner.enabled = true
							fragmentation_btn.enabled = true
			
						)
					
					on randomEdges_btn pressed do
						(
							myFunc.removeRandomEdges()
						)
						
					on nbParts_spinner changed amt do
						(
							nbParts = amt
						)
					
					on fragmentation_btn pressed do
						(
							myFunc.fragmentation()
							generateForm_btn.enabled = true
						)
						
					on generateForm_btn pressed do
						(
							myFunc.generateForm()
							generatePebbles_btn.enabled = true
						)
					
					on generatePebbles_btn pressed do
						(
							myFunc.generatePebbles()
						) 
					
					
		)
	
createDialog generateBox 200 200 --create a dialog with the rollout 