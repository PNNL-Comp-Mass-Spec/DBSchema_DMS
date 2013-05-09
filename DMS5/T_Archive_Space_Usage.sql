/****** Object:  Table [dbo].[T_Archive_Space_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archive_Space_Usage](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Sampling_Date] [datetime] NOT NULL,
	[Data_MB] [bigint] NOT NULL,
	[Files] [int] NULL,
	[Folders] [int] NULL,
	[Comment] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Archive_Space_Usage] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Archive_Space_Usage] ADD  CONSTRAINT [DF_T_Archive_Space_Usage_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Archive_Space_Usage] ADD  CONSTRAINT [DF_T_Archive_Space_Usage_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
