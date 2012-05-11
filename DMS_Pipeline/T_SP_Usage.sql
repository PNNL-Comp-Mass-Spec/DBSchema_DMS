/****** Object:  Table [dbo].[T_SP_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_SP_Usage](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Posted_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Entered] [datetime] NOT NULL,
	[ProcessorID] [int] NULL,
	[Calling_User] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_SP_Usage] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_SP_Usage] ADD  CONSTRAINT [DF_T_SP_Usage_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
