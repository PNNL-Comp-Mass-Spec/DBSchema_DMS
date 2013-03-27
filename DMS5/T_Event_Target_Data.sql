/****** Object:  Table [T_Event_Target] ******/
/****** RowCount: 13 ******/
/****** Columns: ID, Name, Target_Table, Target_ID_Column, Target_State_Column ******/
INSERT INTO [T_Event_Target] VALUES (0,'(none)','(none)','(none)','(none)')
INSERT INTO [T_Event_Target] VALUES (1,'Campaign','T_Campaign','Campaign_ID','(none)')
INSERT INTO [T_Event_Target] VALUES (2,'Cell Culture','T_Cell_Culture','CC_ID','(none)')
INSERT INTO [T_Event_Target] VALUES (3,'Experiment','T_Experiments','Exp_ID','(none)')
INSERT INTO [T_Event_Target] VALUES (4,'Dataset','T_Dataset','Dataset_ID','DS_state_ID')
INSERT INTO [T_Event_Target] VALUES (5,'Analysis Job','T_Analysis_Job','AJ_jobID','AJ_StateID')
INSERT INTO [T_Event_Target] VALUES (6,'Archive','T_Dataset_Archive','AS_Dataset_ID','AS_state_ID')
INSERT INTO [T_Event_Target] VALUES (7,'Archive Update','T_Dataset_Archive','AS_Dataset_ID','AS_update_state_ID')
INSERT INTO [T_Event_Target] VALUES (8,'Dataset Rating','T_Dataset','Dataset_ID','DS_rating')
INSERT INTO [T_Event_Target] VALUES (9,'Campaign Percent EMSL Funded','T_Campaign','Campaign_ID','CM_Fraction_EMSL_Funded')
INSERT INTO [T_Event_Target] VALUES (10,'Campaign Data Release State','T_Campaign','Campaign_ID','CM_Data_Release_Restrictions')
INSERT INTO [T_Event_Target] VALUES (11,'Requested Run','T_Requested_Run','ID','RDS_Status')
INSERT INTO [T_Event_Target] VALUES (12,'Analysis Job Request','T_Analysis_Job_Request','AJR_requestID','AJR_state')
