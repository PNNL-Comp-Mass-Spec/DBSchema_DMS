/****** Object:  Table [T_EMSL_Instrument_Usage_Type] ******/
/****** RowCount: 10 ******/
SET IDENTITY_INSERT [T_EMSL_Instrument_Usage_Type] ON
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (10,'CAP_DEV','Capability Development',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (11,'ONSITE_LEGACY','Onsite research (legacy type)',0)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (12,'MAINTENANCE','Periodic Maintenance',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (13,'BROKEN','Broken, Out of Service',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (14,'AVAILABLE','Available, but not used',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (15,'UNAVAILABLE','Unavailable, but not broken',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (16,'UNAVAIL_STAFF','Staff not available (occasionally used by GetMonthlyInstrumentUsageReport)',0)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (19,'USER_UNKNOWN','EMSL Usage - To be specified later (should rarely be used)',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (20,'ONSITE','Analyzing sample from onsite user',1)
INSERT INTO [T_EMSL_Instrument_Usage_Type] (ID, Name, Description, Enabled) VALUES (21,'REMOTE','Analyzing sample from remote user',1)
SET IDENTITY_INSERT [T_EMSL_Instrument_Usage_Type] OFF
