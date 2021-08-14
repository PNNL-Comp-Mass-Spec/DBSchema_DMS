/****** Object:  Table [T_Enzymes] ******/
/****** RowCount: 23 ******/
SET IDENTITY_INSERT [T_Enzymes] ON
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (0,'na','Not a real value','na','na','na','na','na',0,null,'',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (1,'No_Enzyme','no digestive enzyme was used','na','na','na','na','na',0,0,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (10,'Trypsin','Standard tryptic digest','KR-','na','KR-','na','Standard',1,1,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (11,'GluC','Endoproteinase GluC (aka V8)','ED-','na','ED-','na','Standard',1,12,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (12,'LysC','Endoproteinase LysC','K-','na','K-','na','Standard',1,13,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (13,'CnBR','Cyanogen Bromide','M-','na','M-','na','Standard',1,6,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (14,'Proteinase_K','Proteinase K','GAVLIMCFW-','na','GAVLIMCFWW-','na','Standard',1,15,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (15,'Trypsin_K','Trypsin, after K only','K-','P','K-','P','Standard',1,10,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (16,'Elastase/Tryp/Chymo','Elastase, Trypsin, & Chymotrypsin','ALIVKRWFY-','P','ALIVKRWFY-','P','Standard',1,16,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (17,'Trypsin_Modified','Modified Trypsin','KRLNH-','na','KRLNH-','na','Standard',1,2,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (18,'AspN','AspN','D-','na','D-','na','Standard',0,14,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (19,'Trypsin_R','Trypsin, after R only aka ArgC','R-','P','R-','P','Standard',1,11,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (20,'Chymotrypsin','Chymotrypsin','FWYL-','na','FWYL-','na','Standard',1,3,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (21,'ArgC','Endoproteinase ArgC','R-','na','R-','na','Standard',1,17,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (22,'Do_not_cleave','No cleavage anywhere; used when .Fasta is peptides, not proteins','B','na','B','na','Standard',1,18,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (23,'LysN','LysN metalloendopeptidase','K-','na','K-','na','Standard',0,19,'HumanContam',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (24,'Pepsin','Pepsin','FLWY','na','FLWY','na','Standard',1,null,'HumanContam','Promega Pepsin, Cleaves at the C-Terminus of Phe, Leu, Tyr, Trp; https://www.promega.com/products/mass-spectrometry/proteases-and-surfactants/pepsin/?catNum=V1959')
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (25,'Elastase','Elastase','AVSGLI','na','AVSGLI','na','Standard',1,null,'HumanContam','Promega Elastase, Cleaves at C-Terminus of Ala, Val, Ser, Gly, Leu and Ile; https://www.promega.com/products/mass-spectrometry/proteases-and-surfactants/elastase/?catNum=V1891')
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (26,'LysC_plus_Trypsin','LysC and Trypsin; cleave after K or R if not followed by P, or cleave after K','KR-','na','KR-','na','Standard',1,null,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (27,'TrypN','LysargiNase; cleave before K or R, including if preceded by P','KR','na','KR','na','Standard',0,null,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (28,'Trypsin_plus_Chymotrypsin','Trypsin and Chymotrypsin','KRFWYL-','na','KRFWYL-','na','Standard',1,null,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (29,'Trypsin_plus_GluC','Trypsin and Endoproteinas GluC','KRED-','na','KRED-','na','Standard',1,null,'Tryp_Pig_Bov',null)
INSERT INTO [T_Enzymes] (Enzyme_ID, Enzyme_Name, Description, P1, P1_Exception, P2, P2_Exception, Cleavage_Method, Cleavage_Offset, Sequest_Enzyme_Index, Protein_Collection_Name, Comment) VALUES (30,'ALP','Alpha-Lytic Protease','TASV','na','TASV','na','Standard',1,null,'HumanContam',null)
SET IDENTITY_INSERT [T_Enzymes] OFF
