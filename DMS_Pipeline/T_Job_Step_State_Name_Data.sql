/****** Object:  Table [T_Job_Step_State_Name] ******/
/****** RowCount: 9 ******/
/****** Columns: ID, Name, Description ******/
INSERT INTO [T_Job_Step_State_Name] VALUES (1,'Waiting','Step has not been run yet, and it cannot be assigned yet.')
INSERT INTO [T_Job_Step_State_Name] VALUES (2,'Enabled','Step can be run because all its dependencies have been satisfied')
INSERT INTO [T_Job_Step_State_Name] VALUES (3,'Skipped','Step will not be run because a conditional dependency was triggered.')
INSERT INTO [T_Job_Step_State_Name] VALUES (4,'Running','Step has been assigned to a manager and is being processed')
INSERT INTO [T_Job_Step_State_Name] VALUES (5,'Completed','Manager has successfully completed step')
INSERT INTO [T_Job_Step_State_Name] VALUES (6,'Failed','Manager could not complete step successfully')
INSERT INTO [T_Job_Step_State_Name] VALUES (7,'Holding','Established and removed manually when deus ex machina is necessary')
INSERT INTO [T_Job_Step_State_Name] VALUES (9,'Running_Remote','Job is running on a remote resource (Linux or Cloud)')
INSERT INTO [T_Job_Step_State_Name] VALUES (10,'Holding_Staging','Waiting for the Aurora data archive to stage the required files')
