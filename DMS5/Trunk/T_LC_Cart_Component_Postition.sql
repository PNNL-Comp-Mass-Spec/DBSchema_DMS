/****** Object:  Table [dbo].[T_LC_Cart_Component_Postition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Component_Postition](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Cart_ID] [int] NOT NULL,
	[Position_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_LC_Cart_Component_Postition] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_LC_Cart_Component_Postition] ******/
CREATE NONCLUSTERED INDEX [IX_T_LC_Cart_Component_Postition] ON [dbo].[T_LC_Cart_Component_Postition] 
(
	[Cart_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_LC_Cart_Component_Postition]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Component_Postition_T_LC_Cart] FOREIGN KEY([Cart_ID])
REFERENCES [T_LC_Cart] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart_Component_Postition]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Component_Postition_T_LC_Cart_Positions] FOREIGN KEY([Position_ID])
REFERENCES [T_LC_Cart_Positions] ([ID])
GO
