/****** Object:  Table [dbo].[T_EMSL_Instrument_Usage_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instrument_Usage_Type](
	[ID] [tinyint] IDENTITY(10,1) NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Enabled] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_EMSL_Instrument_Usage_Type] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_EMSL_Instrument_Usage_Type] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_EMSL_Instrument_Usage_Type_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_EMSL_Instrument_Usage_Type_Name] ON [dbo].[T_EMSL_Instrument_Usage_Type]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Type] ADD  CONSTRAINT [DF_T_EMSL_Instrument_Usage_Type_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
