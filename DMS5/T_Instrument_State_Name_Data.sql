/****** Object:  Table [T_Instrument_State_Name] ******/
/****** RowCount: 5 ******/
/****** Columns: State_Name, Description ******/
INSERT INTO [T_Instrument_State_Name] VALUES ('Active','Instrument is online and available to use')
INSERT INTO [T_Instrument_State_Name] VALUES ('Broken','Instrument is broken, but might get repaired')
INSERT INTO [T_Instrument_State_Name] VALUES ('Inactive','Instrument has been retired and will not be brought back online')
INSERT INTO [T_Instrument_State_Name] VALUES ('Offline','Instrument is offline, but might be brought back online in the future')
INSERT INTO [T_Instrument_State_Name] VALUES ('PrepHPLC','Prep LC instrument that is in active use')
