/****** Object:  Table [T_DatasetTypeName] ******/
/****** RowCount: 7 ******/
/****** Columns: DST_Type_ID, DST_name, DST_Description, DST_Active ******/
INSERT INTO [T_DatasetTypeName] VALUES (1,'HMS','High resolution MS spectra only',1)
INSERT INTO [T_DatasetTypeName] VALUES (2,'MS-MSn','Low res MS with low res MSn',1)
INSERT INTO [T_DatasetTypeName] VALUES (3,'HMS-MSn','High res MS with low res MSn',1)
INSERT INTO [T_DatasetTypeName] VALUES (4,'MS','Low resolution MS spectra only',1)
INSERT INTO [T_DatasetTypeName] VALUES (5,'HMS-HMSn','High res MS with high res MSn',1)
INSERT INTO [T_DatasetTypeName] VALUES (6,'IMS-HMS','Ion mobility sep then high res MS detection',0)
INSERT INTO [T_DatasetTypeName] VALUES (7,'IMS-MSn-HMS','Ion mobility sep, fragmentation of all ions, high res MS',0)
