/****** Object:  Table [dbo].[T_Archived_Output_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archived_Output_Files](
	[Archived_File_ID] [int] IDENTITY(1,1) NOT NULL,
	[Archived_File_Type_ID] [int] NOT NULL,
	[Archived_File_State_ID] [int] NOT NULL,
	[Archived_File_Path] [varchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[svn_Repository_Path] [varchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[svn_Revision_Number] [int] NULL,
	[Authentication_Hash] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Filesize] [bigint] NOT NULL,
	[Protein_Count] [int] NULL,
	[Creation_Options] [varchar](250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Archived_File_Creation_Date] [datetime] NOT NULL,
	[File_Modification_Date] [datetime] NOT NULL,
	[Protein_Collection_List] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Collection_List_Hash] [varchar](28) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Collection_List_Hex_Hash] [varchar](40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Archived_Output_Files] PRIMARY KEY CLUSTERED 
(
	[Archived_File_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Archived_Output_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Archived_Output_Files_T_Archived_File_States] FOREIGN KEY([Archived_File_State_ID])
REFERENCES [T_Archived_File_States] ([Archived_File_State_ID])
GO
ALTER TABLE [dbo].[T_Archived_Output_Files] CHECK CONSTRAINT [FK_T_Archived_Output_Files_T_Archived_File_States]
GO
ALTER TABLE [dbo].[T_Archived_Output_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Archived_Output_Files_T_Archived_File_Types] FOREIGN KEY([Archived_File_Type_ID])
REFERENCES [T_Archived_File_Types] ([Archived_File_Type_ID])
GO
ALTER TABLE [dbo].[T_Archived_Output_Files] CHECK CONSTRAINT [FK_T_Archived_Output_Files_T_Archived_File_Types]
GO
