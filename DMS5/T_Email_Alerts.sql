/****** Object:  Table [dbo].[T_Email_Alerts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Email_Alerts](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Posted_by] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Posting_Time] [datetime] NOT NULL,
	[Alert_Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Message] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Recipients] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Alert_State] [tinyint] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Email_Alerts] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Email_Alerts] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Email_Alerts] ADD  CONSTRAINT [DF_T_Email_Alerts_Posting_Time]  DEFAULT (getdate()) FOR [Posting_Time]
GO
ALTER TABLE [dbo].[T_Email_Alerts] ADD  CONSTRAINT [DF_T_Email_Alerts_Alert_Type]  DEFAULT ('Error') FOR [Alert_Type]
GO
ALTER TABLE [dbo].[T_Email_Alerts] ADD  CONSTRAINT [DF_T_Email_Alerts_Alert_State]  DEFAULT ((1)) FOR [Alert_State]
GO
ALTER TABLE [dbo].[T_Email_Alerts] ADD  CONSTRAINT [DF_T_Email_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Email_Alerts]  WITH CHECK ADD  CONSTRAINT [FK_T_Email_Alerts_T_Email_Alert_State] FOREIGN KEY([Alert_State])
REFERENCES [dbo].[T_Email_Alert_State] ([Alert_State])
GO
ALTER TABLE [dbo].[T_Email_Alerts] CHECK CONSTRAINT [FK_T_Email_Alerts_T_Email_Alert_State]
GO
