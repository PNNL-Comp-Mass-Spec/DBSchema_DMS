/****** Object:  Table [dbo].[T_Organisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Organisms](
	[OG_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Organism_ID] [int] IDENTITY(40,1) NOT NULL,
	[OG_organismDBPath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_organismDBLocalPath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_organismDBName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_created] [datetime] NULL,
	[OG_description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Short_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Storage_Location] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Domain] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Kingdom] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Phylum] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Class] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Order] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Family] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Genus] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Species] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Strain] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_DNA_Translation_Table_ID] [int] NULL,
	[OG_Mito_DNA_Translation_Table_ID] [int] NULL,
	[OG_Active] [tinyint] NULL CONSTRAINT [DF_T_Organisms_OG_Active]  DEFAULT (1),
 CONSTRAINT [PK_T_Organisms] PRIMARY KEY NONCLUSTERED 
(
	[Organism_ID] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_Organisms] UNIQUE NONCLUSTERED 
(
	[OG_name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Organisms] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Organisms] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([Organism_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([Organism_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_organismDBPath]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_organismDBPath]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_organismDBLocalPath]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_organismDBLocalPath]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_organismDBName]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_organismDBName]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_description]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_description]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Short_Name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Short_Name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Storage_Location]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Storage_Location]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Domain]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Domain]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Kingdom]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Kingdom]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Phylum]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Phylum]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Class]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Class]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Order]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Order]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Family]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Family]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Genus]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Genus]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Species]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Species]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Strain]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Strain]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_DNA_Translation_Table_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_DNA_Translation_Table_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Mito_DNA_Translation_Table_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Mito_DNA_Translation_Table_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] ([OG_Active]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] ([OG_Active]) TO [Limited_Table_Write]
GO
