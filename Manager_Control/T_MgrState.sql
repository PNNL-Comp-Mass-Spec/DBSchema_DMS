/****** Object:  Table [dbo].[T_MgrState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MgrState](
	[MgrID] [int] NOT NULL,
	[TypeID] [int] NOT NULL,
	[Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_MgrState] PRIMARY KEY CLUSTERED 
(
	[MgrID] ASC,
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT INSERT ON [dbo].[T_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[T_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
ALTER TABLE [dbo].[T_MgrState] ADD  CONSTRAINT [DF_T_MgrState_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
