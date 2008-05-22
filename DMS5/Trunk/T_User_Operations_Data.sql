/****** Object:  Table [T_User_Operations] ******/
/****** RowCount: 6 ******/
SET IDENTITY_INSERT [T_User_Operations] ON
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (16,'DMS_Sample_Preparation','Basic permissions for sample prep techs')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (17,'DMS_Instrument_Operation','Basic permissions for MS instrument operators')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (18,'DMS_Infrastructure_Administration','Permissions for most restricted DMS admin operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (19,'DMS_Ops_Administration','Permissions for general DMS admin operations')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (25,'DMS_Guest','Can look, but not touch')
INSERT INTO [T_User_Operations] (ID, Operation, Operation_Description) VALUES (26,'DMS_User','Permissions for basic operations')
SET IDENTITY_INSERT [T_User_Operations] OFF
