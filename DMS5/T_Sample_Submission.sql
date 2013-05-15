/****** Object:  Table [dbo].[T_Sample_Submission] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Submission](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Campaign_ID] [int] NOT NULL,
	[Received_By_User_ID] [int] NOT NULL,
	[Container_List] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Storage_Path] [int] NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Sample_Submission] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Sample_Submission]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Submission_T_Campaign] FOREIGN KEY([Campaign_ID])
REFERENCES [T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Sample_Submission] CHECK CONSTRAINT [FK_T_Sample_Submission_T_Campaign]
GO
ALTER TABLE [dbo].[T_Sample_Submission]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Submission_T_Prep_File_Storage] FOREIGN KEY([Storage_Path])
REFERENCES [T_Prep_File_Storage] ([ID])
GO
ALTER TABLE [dbo].[T_Sample_Submission] CHECK CONSTRAINT [FK_T_Sample_Submission_T_Prep_File_Storage]
GO
ALTER TABLE [dbo].[T_Sample_Submission]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Submission_T_Users] FOREIGN KEY([Received_By_User_ID])
REFERENCES [T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Sample_Submission] CHECK CONSTRAINT [FK_T_Sample_Submission_T_Users]
GO
ALTER TABLE [dbo].[T_Sample_Submission] ADD  CONSTRAINT [DF_T_Sample_Submission_Created]  DEFAULT (getdate()) FOR [Created]
GO
