/****** Object:  Table [T_User_Operations] ******/
/****** RowCount: 12 ******/
SET IDENTITY_INSERT [T_User_Operations] ON
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (16,'DMS_Sample_Preparation','Permissions for sample prep operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (17,'DMS_Instrument_Operation','Permissions for MS instrument operators (including all permissions that DMS_Dataset_Operation has).  Configure instruments, LC_Carts, and LC Columns.  Create and disposition datasets.  Update Requested Runs, including Run Assignment.')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (18,'DMS_Infrastructure_Administration','Permissions for most restricted DMS admin operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (19,'DMS_Ops_Administration','Permissions for general DMS admin operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (25,'DMS_Guest','Can look, but not touch (Note: PNNL network users who are not listed at http://dms2.pnl.gov/user/report automatically get this permission)')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (26,'DMS_User','Permissions for basic operations (Note: Active DMS users at http://dms2.pnl.gov/user/report automatically get this permission, unless they are tagged with DMS_Guest)')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (32,'DMS_Dataset_Operation','Permission to create and disposition datasets, including with Buzzard. Can also update dataset details.')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (33,'DMS_Analysis_Job_Administration','Permission to add/edit analysis jobs')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (34,'DMS_Instrument_Tracking','Permission for instrument usage tracking admin operations, in particular creating placeholder tracking datasets via http://dms2.pnl.gov/tracking_dataset/create')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (35,'DMS_Data_Analysis_Request','Selectable personnel for data analysis requests')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (36,'DMS_Sample_Prep_Request_State','Permission for updating sample prep request states and for updating operations_tasks items (but not listed in the prep request user picklist)')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (37,'DMS_LC_Column_Entry','Permissions to add/update LC columns and Prep LC columns')
SET IDENTITY_INSERT [T_User_Operations] OFF
