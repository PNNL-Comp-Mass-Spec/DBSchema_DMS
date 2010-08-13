/****** Object:  Table [dbo].[T_Factor_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Factor_Log](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[changed_on] [datetime] NOT NULL,
	[changed_by] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[changes] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Factor_Log] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Factor_Log] ADD  CONSTRAINT [DF_T_Factor_Log_changed_on]  DEFAULT (getdate()) FOR [changed_on]
GO
