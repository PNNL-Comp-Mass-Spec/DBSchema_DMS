/****** Object:  Table [dbo].[T_Operations_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Operations_Tasks](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Tab] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requestor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Personal] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Assigned_Personal] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](5132) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Status] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Priority] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Work_Package] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Closed] [datetime] NULL,
 CONSTRAINT [PK_T_Operations_Tasks] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  DEFAULT ('Normal') FOR [Status]
GO
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  DEFAULT (getdate()) FOR [Created]
GO
