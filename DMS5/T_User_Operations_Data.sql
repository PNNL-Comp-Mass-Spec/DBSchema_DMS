/****** Object:  Table [T_User_Operations] ******/
/****** RowCount: 9 ******/
SET IDENTITY_INSERT [T_User_Operations] ON
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (16,'DMS_Sample_Preparation','Basic permissions for sample prep techs')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (17,'DMS_Instrument_Operation','Basic permissions for MS instrument operators (including all permissions that DMS_Dataset_Operation has).  Configure instruments, LC_Carts, and LC Columns.  Create and disposition datasets.  Update Requested Runs, including Run Assignment.')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (18,'DMS_Infrastructure_Administration','Permissions for most restricted DMS admin operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (19,'DMS_Ops_Administration','Permissions for general DMS admin operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (25,'DMS_Guest','Can look, but not touch (Note: PNNL network users who are not active DMS users automatically get this permission)')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (26,'DMS_User','Permissions for basic operations (Note: Active DMS users automatically get this permission)')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (32,'DMS_Dataset_Operation','Permission to create and dispositon datasets.  Can also update dataset details.')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (33,'DMS_Analysis_Job_Administration','Permission to add/edit analysis jobs')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (34,'DMS_Instrument_Tracking','Permission for instrument usage tracking admin operations, in particular creating placeholder tracking datasets via http://dms2.pnl.gov/tracking_dataset/create')
SET IDENTITY_INSERT [T_User_Operations] OFF
