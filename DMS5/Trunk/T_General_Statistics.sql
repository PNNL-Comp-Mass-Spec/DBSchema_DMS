/****** Object:  Table [dbo].[T_General_Statistics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_General_Statistics](
	[Entry_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Category] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Label] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Last_Affected] [datetime] NULL CONSTRAINT [DF_T_General_Statistics_Last_Affected]  DEFAULT (getdate()),
 CONSTRAINT [PK_T_General_Statistics] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_General_Statistics] ******/
CREATE NONCLUSTERED INDEX [IX_T_General_Statistics] ON [dbo].[T_General_Statistics] 
(
	[Entry_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_General_Statistics_Category_Label] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_General_Statistics_Category_Label] ON [dbo].[T_General_Statistics] 
(
	[Category] ASC,
	[Label] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
