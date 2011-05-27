/****** Object:  Table [dbo].[T_EMSL_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instruments](
	[EUS_Display_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Instrument_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Instrument_ID] [int] NOT NULL,
	[EUS_Available_Hours] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_EMSL_Instruments] PRIMARY KEY CLUSTERED 
(
	[EUS_Instrument_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
