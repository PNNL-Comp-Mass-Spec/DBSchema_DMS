/****** Object:  Table [dbo].[T_Data_Analysis_Request_Updates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Analysis_Request_Updates](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Request_ID] [int] NOT NULL,
	[Old_State_ID] [tinyint] NOT NULL,
	[New_State_ID] [tinyint] NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Data_Analysis_Request_Updates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Analysis_Request_Updates] TO [DDL_Viewer] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Analysis_Request_Updates] ([Entered_By]) TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Analysis_Request_Updates] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
GO
/****** Object:  Index [IX_T_Data_Analysis_Request_Updates_NewState_OldState_Include_RequestID_DateOfChange] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Analysis_Request_Updates_NewState_OldState_Include_RequestID_DateOfChange] ON [dbo].[T_Data_Analysis_Request_Updates]
(
	[New_State_ID] ASC,
	[Old_State_ID] ASC
)
INCLUDE([Request_ID],[Entered]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Data_Analysis_Request_Updates_Request_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Analysis_Request_Updates_Request_ID] ON [dbo].[T_Data_Analysis_Request_Updates]
(
	[Request_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Updates] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_Updates_Date_of_Change]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Updates]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_Updates_T_Data_Analysis_Request_State_Name_After] FOREIGN KEY([New_State_ID])
REFERENCES [dbo].[T_Data_Analysis_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Updates] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_Updates_T_Data_Analysis_Request_State_Name_After]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Updates]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_Updates_T_Data_Analysis_Request_State_Name_Before] FOREIGN KEY([Old_State_ID])
REFERENCES [dbo].[T_Data_Analysis_Request_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Updates] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_Updates_T_Data_Analysis_Request_State_Name_Before]
GO
