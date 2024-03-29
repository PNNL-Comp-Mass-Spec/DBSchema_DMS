/****** Object:  Table [T_Aux_Info_Target] ******/
/****** RowCount: 4 ******/
SET IDENTITY_INSERT [T_Aux_Info_Target] ON
INSERT INTO [T_Aux_Info_Target] (Target_Type_ID, Target_Type_Name, Target_Table, Target_ID_Col, Target_Name_Col) VALUES (500,'Experiment','T_Experiments','Exp_ID','Experiment_Num')
INSERT INTO [T_Aux_Info_Target] (Target_Type_ID, Target_Type_Name, Target_Table, Target_ID_Col, Target_Name_Col) VALUES (501,'Biomaterial','T_Cell_Culture','CC_ID','CC_Name')
INSERT INTO [T_Aux_Info_Target] (Target_Type_ID, Target_Type_Name, Target_Table, Target_ID_Col, Target_Name_Col) VALUES (502,'Dataset','T_Dataset','Dataset_ID','Dataset_Num')
INSERT INTO [T_Aux_Info_Target] (Target_Type_ID, Target_Type_Name, Target_Table, Target_ID_Col, Target_Name_Col) VALUES (503,'SamplePrepRequest','T_Sample_Prep_Request','ID','ID')
SET IDENTITY_INSERT [T_Aux_Info_Target] OFF
