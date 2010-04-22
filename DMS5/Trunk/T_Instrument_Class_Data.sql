/****** Object:  Table [T_Instrument_Class] ******/
/****** RowCount: 13 ******/
/****** Columns: IN_class, is_purgable, raw_data_type, requires_preparation, Allowed_Dataset_Types ******/
INSERT INTO [T_Instrument_Class] VALUES ('Agilent_Ion_Trap',0,'dot_d_folders',0,'MS, MS-MSn')
INSERT INTO [T_Instrument_Class] VALUES ('Agilent_TOF',0,'dot_wiff_files',0,'HMS')
INSERT INTO [T_Instrument_Class] VALUES ('BRUKERFTMS',1,'zipped_s_folders',1,'HMS, HMS-HMSn')
INSERT INTO [T_Instrument_Class] VALUES ('Finnigan_FTICR',1,'zipped_s_folders',1,'HMS, HMS-HMSn')
INSERT INTO [T_Instrument_Class] VALUES ('Finnigan_Ion_Trap',1,'dot_raw_files',0,'MS, MS-MSn, MS-ETD-MSn, MS-CID/ETD-MSn')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Agilent_TOF',1,'dot_uimf_files',0,'IMS-HMS, IMS-MSn-HMS')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Biospect_TOF',0,'biospec_folder',0,'IMS-HMS, IMS-MSn-HMS')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Sciex_TOF',0,'dot_wiff_files',0,'IMS-HMS, IMS-MSn-HMS')
INSERT INTO [T_Instrument_Class] VALUES ('LTQ_FT',1,'dot_raw_files',0,'MS-MSn, HMS, HMS-MSn, HMS-HMSn, HMS-ETD-MSn, HMS-CID/ETD-MSn')
INSERT INTO [T_Instrument_Class] VALUES ('Micromass_QTOF',0,'dot_raw_folder',0,'HMS, HMS-HMSn')
INSERT INTO [T_Instrument_Class] VALUES ('QStar_QTOF',0,'dot_wiff_files',0,'HMS, HMS-HMSn')
INSERT INTO [T_Instrument_Class] VALUES ('Thermo_Exactive',1,'dot_raw_files',0,'HMS')
INSERT INTO [T_Instrument_Class] VALUES ('Triple_Quad',1,'dot_raw_files',0,'MS, MS-MSn, MRM')
