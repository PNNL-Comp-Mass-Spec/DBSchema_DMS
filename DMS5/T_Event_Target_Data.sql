/****** Object:  Table [T_Event_Target] ******/
/****** RowCount: 16 ******/
/****** Columns: ID, Name, Target_Table, Target_ID_Column, Target_State_Column ******/
INSERT INTO [T_Event_Target] VALUES (0,'(none)','(none)','(none)','(none)')
INSERT INTO [T_Event_Target] VALUES (1,'Campaign','t_campaign','campaign_id','(none)')
INSERT INTO [T_Event_Target] VALUES (2,'Biomaterial','t_biomaterial','biomaterial_id','(none)')
INSERT INTO [T_Event_Target] VALUES (3,'Experiment','t_experiments','exp_id','(none)')
INSERT INTO [T_Event_Target] VALUES (4,'Dataset','t_dataset','dataset_id','dataset_state_id')
INSERT INTO [T_Event_Target] VALUES (5,'Analysis Job','t_analysis_job','job','job_state_id')
INSERT INTO [T_Event_Target] VALUES (6,'Archive','t_dataset_archive','dataset_id','archive_state_id')
INSERT INTO [T_Event_Target] VALUES (7,'Archive Update','t_dataset_archive','dataset_id','archive_update_state_id')
INSERT INTO [T_Event_Target] VALUES (8,'Dataset Rating','t_dataset','dataset_id','dataset_rating_id')
INSERT INTO [T_Event_Target] VALUES (9,'Campaign Percent EMSL Funded','t_campaign','campaign_id','fraction_emsl_funded')
INSERT INTO [T_Event_Target] VALUES (10,'Campaign Data Release State','t_campaign','campaign_id','data_release_restrictions')
INSERT INTO [T_Event_Target] VALUES (11,'Requested Run','t_requested_run','request_id','state_name')
INSERT INTO [T_Event_Target] VALUES (12,'Analysis Job Request','t_analysis_job_request','request_id','request_state_id')
INSERT INTO [T_Event_Target] VALUES (13,'Reference Compound','t_reference_compound','compound_id','(none)')
INSERT INTO [T_Event_Target] VALUES (14,'Requested Run Dataset ID','t_requested_run','dataset_id','(none)')
INSERT INTO [T_Event_Target] VALUES (15,'Requested Run Experiment ID','t_requested_run','exp_id','(none)')
