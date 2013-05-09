/****** Object:  Table [dbo].[T_LC_Cart_Config_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Config_History](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Cart] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Date_Of_Change] [datetime] NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[EnteredBy] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_LC_Cart_Config_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_LC_Cart_Config_History] ADD  CONSTRAINT [DF_T_LC_Cart_Config_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
