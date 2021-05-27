/****** Object:  Table [T_Acceptable_Param_Entry_Types] ******/
/****** RowCount: 9 ******/
SET IDENTITY_INSERT [T_Acceptable_Param_Entry_Types] ON
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (1,'Integer',null,'(?<value>\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (2,'MinMax',null,'(?<minimum>\d+\.\d+)\s+(?<maximum>\d+\.\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (3,'Text',null,'(?<value>\S+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (4,'NumericPicklist',null,'(?<value>\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (5,'IonSeries',null,'(?<use_a_ions>[0|1])\s+(?<use_b_ions>[0|1])\s+(?<use_y_ions>[0|1])\s+(?<a_ion_weighting>\d+\.\d+)\s+(?<b_ion_weighting>\d+\.\d+)\s+(?<c_ion_weighting>\d+\.\d+)\s+(?<d_ion_weighting>\d+\.\d+)\s+(?<v_ion_weighting>\d+\.\d+)\s+(?<w_ion_weighting>\d+\.\d+)\s+(?<x_ion_weighting>\d+\.\d+)\s+(?<y_ion_weighting>\d+\.\d+)\s+(?<z_ion_weighting>\d+\.\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (6,'DiffMod',null,'(?<modMass>\d+\.\d+)\s+(?<affectedResidues>\s+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (7,'Float',null,'(?<value>\d+\.\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (8,'Boolean',null,'(?<value>[0|1])')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (9,'TermDiffMod',null,'(?<nTermMass>\d+\.\d+)\s+(?<cTermMass>\d+\.\d+)')
SET IDENTITY_INSERT [T_Acceptable_Param_Entry_Types] OFF
