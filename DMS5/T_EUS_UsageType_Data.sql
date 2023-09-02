/****** Object:  Table [T_EUS_UsageType] ******/
/****** RowCount: 9 ******/
SET IDENTITY_INSERT [T_EUS_UsageType] ON
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (1,'Undefined','Undefined type; not valid for requested runs',0,0,0)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (10,'CAP_DEV','Capability Development',1,1,1)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (12,'MAINTENANCE','Maintenance',1,0,0)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (13,'BROKEN','Broken (out of service)',1,0,0)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (16,'USER','On-Site usage (legacy name)',0,0,0)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (19,'USER_UNKNOWN','EMSL Usage - To be specified later (should rarely be used)',0,0,0)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (20,'USER_ONSITE','Samples analyzed onsite by originating user; prior to FY24, also used for samples associated with Resource Owner proposals',1,1,1)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (21,'USER_REMOTE','Samples analyzed by instrumentation staff for an EMSL user',1,1,1)
INSERT INTO [T_EUS_UsageType] (ID, Name, Description, Enabled, Enabled_Campaign, Enabled_Prep_Request) VALUES (22,'RESOURCE_OWNER','Resource Owner samples (which no longer need to have a proposal, effective FY24)',1,1,1)
SET IDENTITY_INSERT [T_EUS_UsageType] OFF
