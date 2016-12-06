/****** Object:  Table [dbo].[T_Factor] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Factor](
	[FactorID] [int] IDENTITY(1,1) NOT NULL,
	[Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[TargetID] [int] NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Updated] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_T_Factor] PRIMARY KEY NONCLUSTERED 
(
	[FactorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Factor] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Factor_Type_TargetID_Name] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_Factor_Type_TargetID_Name] ON [dbo].[T_Factor]
(
	[Type] ASC,
	[TargetID] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Factor] ADD  CONSTRAINT [DF_T_Factor_Type]  DEFAULT ('Run_Request') FOR [Type]
GO
ALTER TABLE [dbo].[T_Factor] ADD  CONSTRAINT [DF_T_Factor_Last_Updated]  DEFAULT (getdate()) FOR [Last_Updated]
GO
