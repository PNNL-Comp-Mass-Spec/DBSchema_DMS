/****** Object:  Table [T_Acceptable_Param_Entry_Types] ******/
/****** RowCount: 9 ******/
SET IDENTITY_INSERT [T_Acceptable_Param_Entry_Types] ON
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (1,'Integer','','(?<value>\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (2,'MinMax','','(?<minimum>\d+\.\d+)\s+(?<maximum>\d+\.\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (3,'Text','','(?<value>\S+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (4,'NumericPicklist','','(?<value>\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (5,'IonSeries','','(?<use_a_ions>[0|1])\s+(?<use_b_ions>[0|1])\s+(?<use_y_ions>[0|1])\s+(?<a_ion_weighting>\d+\.\d+)\s+(?<b_ion_weighting>\d+\.\d+)\s+(?<c_ion_weighting>\d+\.\d+)\s+(?<d_ion_weighting>\d+\.\d+)\s+(?<v_ion_weighting>\d+\.\d+)\s+(?<w_ion_weighting>\d+\.\d+)\s+(?<x_ion_weighting>\d+\.\d+)\s+(?<y_ion_weighting>\d+\.\d+)\s+(?<z_ion_weighting>\d+\.\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (6,'DiffMod','','(?<modMass>\d+\.\d+)\s+(?<affectedResidues>\s+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (7,'Float','','(?<value>\d+\.\d+)')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (8,'Boolean','','(?<value>[0|1])')
INSERT INTO [T_Acceptable_Param_Entry_Types] (Param_Entry_Type_ID, Param_Entry_Type_Name, Description, Formatting_String) VALUES (9,'TermDiffMod','','(?<nTermMass>\d+\.\d+)\s+(?<cTermMass>\d+\.\d+)')
SET IDENTITY_INSERT [T_Acceptable_Param_Entry_Types] OFF
