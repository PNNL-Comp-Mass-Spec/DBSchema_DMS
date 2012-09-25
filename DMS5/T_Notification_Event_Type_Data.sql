/****** Object:  Table [T_Notification_Event_Type] ******/
/****** RowCount: 13 ******/
/****** Columns: ID, Name, Target_Entity_Type, Link_Template, Visible ******/
INSERT INTO [T_Notification_Event_Type] VALUES (1,'Requested Run Batch Start',1,'requested_run_batch/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (2,'Requested Run Batch Finish',1,'requested_run_batch/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (3,'Requested Run Batch Acq Time Ready',1,'','N')
INSERT INTO [T_Notification_Event_Type] VALUES (4,'Analysis Job Request Start',2,'analysis_job_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (5,'Analysis Job Request Finish',2,'analysis_job_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (11,'Sample Prep Req (New)',3,'sample_prep_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (12,'Sample Prep Req (Open)',3,'sample_prep_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (13,'Sample Prep Req (Prep in Progress)',3,'sample_prep_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (14,'Sample Prep Req (Prep Complete)',3,'sample_prep_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (15,'Sample Prep Req (Closed)',3,'sample_prep_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (16,'Sample Prep Req (Pending Approval)',3,'sample_prep_request/show/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (20,'Dataset Not Released',4,'dataset/report/-/@ID@','Y')
INSERT INTO [T_Notification_Event_Type] VALUES (21,'Dataset Released',5,'dataset/report/-/@ID@','Y')
