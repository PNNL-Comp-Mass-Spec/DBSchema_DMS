/****** Object:  Table [dbo].[T_Sample_Prep_Request_Updates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Prep_Request_Updates](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Request_ID] [int] NOT NULL,
	[System_Account] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Date_of_Change] [datetime] NOT NULL CONSTRAINT [DF_T_Sample_Prep_Request_Updates_Date_of_Change]  DEFAULT (getdate()),
	[Beginning_State_ID] [tinyint] NOT NULL,
	[End_State_ID] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Sample_Prep_Request_Updates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Updates]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_Updates_T_Sample_Prep_Request] FOREIGN KEY([Request_ID])
REFERENCES [T_Sample_Prep_Request] ([ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Updates] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_Updates_T_Sample_Prep_Request]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Updates]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_Updates_T_Sample_Prep_Request_State_Name] FOREIGN KEY([Beginning_State_ID])
REFERENCES [T_Sample_Prep_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Updates] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_Updates_T_Sample_Prep_Request_State_Name]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Updates]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_Updates_T_Sample_Prep_Request_State_Name1] FOREIGN KEY([End_State_ID])
REFERENCES [T_Sample_Prep_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Updates] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_Updates_T_Sample_Prep_Request_State_Name1]
GO
