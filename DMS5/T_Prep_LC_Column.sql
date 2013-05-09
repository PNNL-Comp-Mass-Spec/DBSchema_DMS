/****** Object:  Table [dbo].[T_Prep_LC_Column] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Prep_LC_Column](
	[Column_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mfg_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mfg_Model] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mfg_Serial_Number] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Packing_Mfg] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Packing_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Particle_size] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Particle_type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Column_Inner_Dia] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Column_Outer_Dia] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Length] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Operator_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](244) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[ID] [int] IDENTITY(1000,1) NOT NULL,
 CONSTRAINT [PK_T_Prep_LC_Column] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Prep_LC_Column] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Prep_LC_Column] ON [dbo].[T_Prep_LC_Column] 
(
	[Column_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Prep_LC_Column]  WITH CHECK ADD  CONSTRAINT [CK_T_Prep_LC_Column_ColumnName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Column_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Prep_LC_Column] CHECK CONSTRAINT [CK_T_Prep_LC_Column_ColumnName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Prep_LC_Column] ADD  CONSTRAINT [DF_T_Prep_LC_Column_PC_Packing_Mfg]  DEFAULT ('na') FOR [Packing_Mfg]
GO
ALTER TABLE [dbo].[T_Prep_LC_Column] ADD  CONSTRAINT [DF_T_Prep_LC_Column_PC_State]  DEFAULT ('New') FOR [State]
GO
ALTER TABLE [dbo].[T_Prep_LC_Column] ADD  CONSTRAINT [DF_T_Prep_LC_Column_Created]  DEFAULT (getdate()) FOR [Created]
GO
