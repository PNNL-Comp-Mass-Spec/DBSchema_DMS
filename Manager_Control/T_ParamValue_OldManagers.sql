/****** Object:  Table [dbo].[T_ParamValue_OldManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_ParamValue_OldManagers](
	[Entry_ID] [int] NOT NULL,
	[TypeID] [int] NOT NULL,
	[Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MgrID] [int] NOT NULL,
	[Last_Affected] [datetime] NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_ParamValue_OldManagers] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
