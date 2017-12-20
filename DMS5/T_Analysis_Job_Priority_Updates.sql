/****** Object:  Table [dbo].[T_Analysis_Job_Priority_Updates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Priority_Updates](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Job] [int] NOT NULL,
	[Old_Priority] [smallint] NOT NULL,
	[New_Priority] [smallint] NOT NULL,
	[Comment] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_Priority_Updates] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Analysis_Job_Priority_Updates_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Priority_Updates_Job] ON [dbo].[T_Analysis_Job_Priority_Updates]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
