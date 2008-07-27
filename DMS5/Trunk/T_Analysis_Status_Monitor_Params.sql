/****** Object:  Table [dbo].[T_Analysis_Status_Monitor_Params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Status_Monitor_Params](
	[ProcessorID] [int] NOT NULL,
	[StatusFileNamePath] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CheckBoxState] [tinyint] NOT NULL CONSTRAINT [DF_T_Analysis_Status_Monitor_Params_CheckBoxState]  DEFAULT (0),
	[UseForStatusCheck] [tinyint] NOT NULL CONSTRAINT [DF_T_Analysis_Status_Monitor_Params_UseForStatusCheck]  DEFAULT (1),
 CONSTRAINT [IX_T_Analysis_Status_Monitor_Params] UNIQUE NONCLUSTERED 
(
	[ProcessorID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
