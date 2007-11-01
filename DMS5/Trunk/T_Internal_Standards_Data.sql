/****** Object:  Table [T_Internal_Standards] ******/
/****** RowCount: 14 ******/
SET IDENTITY_INSERT [T_Internal_Standards] ON
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (0,,'unknown','status uncertain','All','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (1,,'none','Nothing added','All','A')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (2,1,'PepChromeA','5 elution time marker peptides','Postdigest','A')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (3,2,'MiniProteomeA','5 proteins added prior to digestion (development work)','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (4,3,'MiniProteomeB','3 proteins added prior to digestion; 6 peptides after digestion','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (5,4,'MP_05_01','Official mini proteome, October 2005 batch','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (6,4,'MP_06_01','Official mini proteome, March 2006 batch','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (7,4,'mini-proteome','General mini-proteome','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (8,4,'MP_06_02','Official mini proteome, October 2006 batch','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (9,4,'MP_06_03','Official mini proteome, December 2006 batch','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (10,5,'QC_05_03','QC Standards mixture, 2005 batch','Predigest','I')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (11,4,'MP_07_01','Official mini proteome, January 2007 batch','Predigest','A')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (12,4,'MP_07_02','Official mini proteome, April 2007 batch','Predigest','A')
INSERT INTO [T_Internal_Standards] (Internal_Std_Mix_ID, Internal_Std_Parent_Mix_ID, Name, Description, Type, Active) VALUES (13,4,'MP_07_03','Official mini proteome, July 2007 batch','Predigest','A')
SET IDENTITY_INSERT [T_Internal_Standards] OFF
