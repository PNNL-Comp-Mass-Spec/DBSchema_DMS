/****** Object:  Table [T_Protein_Collection_Types] ******/
/****** RowCount: 6 ******/
SET IDENTITY_INSERT [T_Protein_Collection_Types] ON
INSERT INTO [T_Protein_Collection_Types] (Collection_Type_ID, Type, Display, Description) VALUES (1,'protein_file','Loaded Protein File','Loaded from pre-existing (possibly annotated) protein source file')
INSERT INTO [T_Protein_Collection_Types] (Collection_Type_ID, Type, Display, Description) VALUES (2,'nucleotide_sequence','Translated File','Translated locally from genomic sequence into a stored collection')
INSERT INTO [T_Protein_Collection_Types] (Collection_Type_ID, Type, Display, Description) VALUES (3,'combined','Combined','Made from subsets (or the entirety) of one or more existing static collections')
INSERT INTO [T_Protein_Collection_Types] (Collection_Type_ID, Type, Display, Description) VALUES (4,'contaminant','Contaminants','Potential contaminant proteins')
INSERT INTO [T_Protein_Collection_Types] (Collection_Type_ID, Type, Display, Description) VALUES (5,'internal_standard','Internal Standard','Internal standard proteins')
INSERT INTO [T_Protein_Collection_Types] (Collection_Type_ID, Type, Display, Description) VALUES (6,'old_contaminant','Old Contaminants','Potential contaminant proteins')
SET IDENTITY_INSERT [T_Protein_Collection_Types] OFF
