/****** Object:  Table [T_Event_Target] ******/
/****** RowCount: 8 ******/
/****** Columns: ID, Name, Target_Table, Target_ID_Column, Target_State_Column ******/
INSERT INTO [T_Event_Target] VALUES (0,'(none)','(none)','(none)','(none)')
INSERT INTO [T_Event_Target] VALUES (1,'Campaign','T_Campaign','Campaign_ID','(none)')
INSERT INTO [T_Event_Target] VALUES (2,'Cell Culture','T_Cell_Culture','CC_ID','(none)')
INSERT INTO [T_Event_Target] VALUES (3,'Experiment','T_Experiments','Exp_ID','(none)')
INSERT INTO [T_Event_Target] VALUES (4,'Dataset','T_Dataset','Dataset_ID','DS_state_ID')
INSERT INTO [T_Event_Target] VALUES (5,'Analysis Job','T_Analysis_Job','AJ_jobID','AJ_StateID')
INSERT INTO [T_Event_Target] VALUES (6,'Archive','T_Dataset_Archive','AS_Dataset_ID','AS_state_ID')
INSERT INTO [T_Event_Target] VALUES (7,'Archive Update','T_Dataset_Archive','AS_Dataset_ID','AS_update_state_ID')
