/****** Object:  Table [dbo].[T_Scripts_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Scripts_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[ID] [int] NOT NULL,
	[Script] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Results_Tag] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Contents] [xml] NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Scripts_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Scripts_History] TO [DMS_SP_User] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Scripts_History] TO [DMS_SP_User] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Scripts_History] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Scripts_History] TO [DMS_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Scripts_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Scripts_History_T_Scripts] FOREIGN KEY([Script])
REFERENCES [T_Scripts] ([Script])
GO
ALTER TABLE [dbo].[T_Scripts_History] CHECK CONSTRAINT [FK_T_Scripts_History_T_Scripts]
GO
ALTER TABLE [dbo].[T_Scripts_History] ADD  CONSTRAINT [DF_T_Scripts_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Scripts_History] ADD  CONSTRAINT [DF_T_Scripts_History_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
