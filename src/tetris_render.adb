with Tetris_Font;
with SDL;
with SDL.Video;
with SDL.Video.Palettes;
with SDL.Video.Rectangles;

package body Tetris_Render is
   use Tetris_Game;

   Cell_Size    : constant := 30;
   Board_X      : constant := 30;
   Board_Y      : constant := 90;
   Panel_X      : constant := 360;
   Preview_Cell : constant := 16;

   Background : constant SDL.Video.Palettes.Colour := (16, 16, 22, 255);
   Board_Bg   : constant SDL.Video.Palettes.Colour := (10, 10, 14, 255);
   Grid_Line  : constant SDL.Video.Palettes.Colour := (30, 30, 38, 255);
   Frame      : constant SDL.Video.Palettes.Colour := (95, 95, 112, 255);
   Text       : constant SDL.Video.Palettes.Colour := (232, 232, 238, 255);
   Muted      : constant SDL.Video.Palettes.Colour := (140, 140, 156, 255);
   Banner     : constant SDL.Video.Palettes.Colour := (255, 220, 90, 255);

   function Rect
     (X, Y, W, H : Integer) return SDL.Video.Rectangles.Rectangle is
     ((X      => SDL.Coordinate (X),
       Y      => SDL.Coordinate (Y),
       Width  => SDL.Natural_Dimension (W),
       Height => SDL.Natural_Dimension (H)));

   function Piece_Colour (Kind : Piece_Kinds) return SDL.Video.Palettes.Colour is
     (case Kind is
        when I => (Red => 0,   Green => 220, Blue => 230, Alpha => 255),
        when O => (Red => 240, Green => 208, Blue => 40,  Alpha => 255),
        when T => (Red => 168, Green => 72,  Blue => 232, Alpha => 255),
        when S => (Red => 72,  Green => 208, Blue => 92,  Alpha => 255),
        when Z => (Red => 232, Green => 60,  Blue => 68,  Alpha => 255),
        when J => (Red => 58,  Green => 108, Blue => 240, Alpha => 255),
        when L => (Red => 240, Green => 148, Blue => 48,  Alpha => 255));

   function Mix
     (C      : SDL.Video.Palettes.Colour;
      Amount : Integer) return SDL.Video.Palettes.Colour
   is
      function Ch (V : SDL.Video.Palettes.Colour_Component)
        return SDL.Video.Palettes.Colour_Component is
        (SDL.Video.Palettes.Colour_Component
           (Integer'Max (0, Integer'Min (255, Integer (V) + Amount))));
   begin
      return (Red => Ch (C.Red), Green => Ch (C.Green),
              Blue => Ch (C.Blue), Alpha => C.Alpha);
   end Mix;

   procedure Draw_Block
     (Rend : in out SDL.Video.Renderers.Renderer;
      PX, PY, S : Integer;
      C    : SDL.Video.Palettes.Colour)
   is
   begin
      Rend.Set_Draw_Colour (Mix (C, -60));
      Rend.Fill (Rect (PX, PY, S, S));

      Rend.Set_Draw_Colour (C);
      Rend.Fill (Rect (PX + 1, PY + 1, S - 2, S - 2));

      Rend.Set_Draw_Colour (Mix (C, 50));
      Rend.Fill (Rect (PX + 2, PY + 2, S - 4, 3));
      Rend.Fill (Rect (PX + 2, PY + 2, 3, S - 4));

      Rend.Set_Draw_Colour (Mix (C, -70));
      Rend.Fill (Rect (PX + 2, PY + S - 5, S - 4, 3));
      Rend.Fill (Rect (PX + S - 5, PY + 2, 3, S - 4));
   end Draw_Block;

   procedure Draw_Ghost_Cell
     (Rend : in out SDL.Video.Renderers.Renderer;
      PX, PY, S : Integer;
      C    : SDL.Video.Palettes.Colour)
   is
   begin
      Rend.Set_Draw_Colour (Mix (C, -80));
      Rend.Draw (Rect (PX + 1, PY + 1, S - 2, S - 2));
      Rend.Draw (Rect (PX + 2, PY + 2, S - 4, S - 4));
   end Draw_Ghost_Cell;

   procedure Draw_Preview
     (Rend : in out SDL.Video.Renderers.Renderer;
      Kind : Piece_Kinds;
      X, Y : Integer)
   is
      S     : constant Shape_Grid := Shape (Kind, 0);
      N     : constant Positive   := Piece_Size (Kind);
      Box   : constant Integer    := 4 * Preview_Cell;
      Min_R : Integer := N;
      Max_R : Integer := -1;
      Min_C : Integer := N;
      Max_C : Integer := -1;
      W, H  : Integer;
      OX, OY : Integer;
   begin
      for R in 0 .. N - 1 loop
         for C in 0 .. N - 1 loop
            if S (R, C) then
               Min_R := Integer'Min (Min_R, R);
               Max_R := Integer'Max (Max_R, R);
               Min_C := Integer'Min (Min_C, C);
               Max_C := Integer'Max (Max_C, C);
            end if;
         end loop;
      end loop;

      W := (Max_C - Min_C + 1) * Preview_Cell;
      H := (Max_R - Min_R + 1) * Preview_Cell;
      OX := X + (Box - W) / 2 - Min_C * Preview_Cell;
      OY := Y + (Box - H) / 2 - Min_R * Preview_Cell;

      for R in 0 .. N - 1 loop
         for C in 0 .. N - 1 loop
            if S (R, C) then
               Draw_Block (Rend, OX + C * Preview_Cell, OY + R * Preview_Cell,
                           Preview_Cell, Piece_Colour (Kind));
            end if;
         end loop;
      end loop;
   end Draw_Preview;

   procedure Draw_Board
     (Rend : in out SDL.Video.Renderers.Renderer;
      G    : Game)
   is
   begin
      Rend.Set_Draw_Colour (Board_Bg);
      Rend.Fill (Rect (Board_X, Board_Y, Board_Width * Cell_Size, Board_Height * Cell_Size));

      Rend.Set_Draw_Colour (Grid_Line);
      for C in 0 .. Board_Width loop
         Rend.Fill (Rect (Board_X + C * Cell_Size, Board_Y, 1, Board_Height * Cell_Size));
      end loop;
      for R in 0 .. Board_Height loop
         Rend.Fill (Rect (Board_X, Board_Y + R * Cell_Size, Board_Width * Cell_Size, 1));
      end loop;

      for Row in Visible_First_Row .. Board_Rows loop
         for Col in 1 .. Board_Width loop
            declare
               State : constant Cell_States := Cell (G, Row, Col);
            begin
               if State /= Empty then
                  Draw_Block
                    (Rend,
                     Board_X + (Col - 1) * Cell_Size,
                     Board_Y + (Row - Visible_First_Row) * Cell_Size,
                     Cell_Size,
                     Piece_Colour (Piece_Kinds (State)));
               end if;
            end;
         end loop;
      end loop;

      if G.Status = Playing then
         declare
            S  : constant Shape_Grid := Shape (G.Current, G.Rotation);
            N  : constant Positive   := Piece_Size (G.Current);
            GY : constant Integer    := Ghost_Y (G);
         begin
            for R in 0 .. N - 1 loop
               for C in 0 .. N - 1 loop
                  if S (R, C) and then GY + R >= Visible_First_Row then
                     Draw_Ghost_Cell
                       (Rend,
                        Board_X + (G.X + C - 1) * Cell_Size,
                        Board_Y + (GY + R - Visible_First_Row) * Cell_Size,
                        Cell_Size,
                        Piece_Colour (G.Current));
                  end if;
               end loop;
            end loop;

            for R in 0 .. N - 1 loop
               for C in 0 .. N - 1 loop
                  if S (R, C) and then G.Y + R >= Visible_First_Row then
                     Draw_Block
                       (Rend,
                        Board_X + (G.X + C - 1) * Cell_Size,
                        Board_Y + (G.Y + R - Visible_First_Row) * Cell_Size,
                        Cell_Size,
                        Piece_Colour (G.Current));
                  end if;
               end loop;
            end loop;
         end;
      end if;

      Rend.Set_Draw_Colour (Frame);
      Rend.Draw (Rect (Board_X - 3, Board_Y - 3,
                       Board_Width * Cell_Size + 6, Board_Height * Cell_Size + 6));
      Rend.Draw (Rect (Board_X - 2, Board_Y - 2,
                       Board_Width * Cell_Size + 4, Board_Height * Cell_Size + 4));
   end Draw_Board;

   procedure Draw_Hud
     (Rend : in out SDL.Video.Renderers.Renderer;
      G    : Game)
   is
      subtype Control_Line is String (1 .. 18);
      Controls : constant array (1 .. 6) of Control_Line :=
        ("ARROWS  MOVE      ",
         "UP X    ROTATE    ",
         "Z       ROTATE CCW",
         "SPACE   DROP      ",
         "C       HOLD      ",
         "P       PAUSE     ");
   begin
      Tetris_Font.Draw_Text (Rend, Panel_X, 90, 2, "NEXT", Muted);
      for Idx in 1 .. 3 loop
         Draw_Preview
           (Rend, G.Next_Queue (Idx), Panel_X + 24, 112 + (Idx - 1) * 82);
      end loop;

      Tetris_Font.Draw_Text (Rend, Panel_X, 380, 2, "HOLD", Muted);
      if G.Has_Hold then
         Draw_Preview (Rend, G.Hold_Kind, Panel_X + 24, 404);
      end if;

      Tetris_Font.Draw_Text (Rend, Panel_X, 500, 2, "SCORE", Muted);
      Tetris_Font.Draw_Text (Rend, Panel_X, 520, 3, Natural'Image (G.Score), Text);

      Tetris_Font.Draw_Text (Rend, Panel_X, 560, 2, "LEVEL", Muted);
      Tetris_Font.Draw_Text (Rend, Panel_X + 108, 560, 2, Natural'Image (G.Level), Text);

      Tetris_Font.Draw_Text (Rend, Panel_X, 582, 2, "LINES", Muted);
      Tetris_Font.Draw_Text (Rend, Panel_X + 108, 582, 2, Natural'Image (G.Lines), Text);

      for Idx in Controls'Range loop
         Tetris_Font.Draw_Text
           (Rend, Panel_X, 620 + (Idx - 1) * 10, 1, Controls (Idx), Muted);
      end loop;
   end Draw_Hud;

   procedure Draw
     (Rend   : in out SDL.Video.Renderers.Renderer;
      G      : Tetris_Game.Game;
      Paused : Boolean)
   is
   begin
      Rend.Set_Blend_Mode (SDL.Video.None);
      Rend.Set_Draw_Colour (Background);
      Rend.Clear;

      Tetris_Font.Draw_Text (Rend, Board_X, 28, 4, "TETRIS", Text);
      Tetris_Font.Draw_Text (Rend, Board_X + 160, 42, 2, "ADA + SDL2", Muted);

      Draw_Board (Rend, G);
      Draw_Hud (Rend, G);

      if G.Message_Timer > 0 and then G.Last_Clear >= 2 then
         declare
            Msg : constant String :=
              (case G.Last_Clear is
                 when 2      => "DOUBLE",
                 when 3      => "TRIPLE",
                 when others => "TETRIS!");
            W : constant Natural := Tetris_Font.Text_Width (Msg, 3);
            Y : constant Integer := Board_Y + 36;
         begin
            Rend.Set_Draw_Colour ((10, 10, 14, 220));
            Rend.Fill (Rect (Board_X + 10, Y - 8, Board_Width * Cell_Size - 20, 37));
            Tetris_Font.Draw_Text
              (Rend, Board_X + (Board_Width * Cell_Size - Integer (W)) / 2, Y,
               3, Msg, Banner);
         end;
      end if;

      if G.Status = Game_Over then
         Rend.Set_Blend_Mode (SDL.Video.Alpha_Blend);
         Rend.Set_Draw_Colour ((5, 5, 9, 190));
         Rend.Fill (Rect (0, 0, Window_Width, Window_Height));
         Rend.Set_Blend_Mode (SDL.Video.None);

         Rend.Set_Draw_Colour ((14, 14, 20, 255));
         Rend.Fill (Rect (110, 190, 440, 320));
         Rend.Set_Draw_Colour (Frame);
         Rend.Draw (Rect (110, 190, 440, 320));

         declare
            function Centre (S : String; Scale : Positive) return Integer is
              ((Window_Width - Integer (Tetris_Font.Text_Width (S, Scale))) / 2);
         begin
            Tetris_Font.Draw_Text (Rend, Centre ("GAME OVER", 4), 230, 4, "GAME OVER", Text);
            Tetris_Font.Draw_Text (Rend, Centre ("SCORE", 2), 300, 2, "SCORE", Muted);
            Tetris_Font.Draw_Text
              (Rend, Centre (Natural'Image (G.Score), 4), 322, 4,
               Natural'Image (G.Score), Text);
            Tetris_Font.Draw_Text (Rend, Centre ("R  RESTART", 2), 400, 2, "R  RESTART", Text);
            Tetris_Font.Draw_Text (Rend, Centre ("Q  QUIT", 2), 432, 2, "Q  QUIT", Muted);
         end;

      elsif Paused then
         Rend.Set_Blend_Mode (SDL.Video.Alpha_Blend);
         Rend.Set_Draw_Colour ((5, 5, 9, 190));
         Rend.Fill (Rect (Board_X, Board_Y, Board_Width * Cell_Size, Board_Height * Cell_Size));
         Rend.Set_Blend_Mode (SDL.Video.None);

         declare
            function Centre (S : String; Scale : Positive) return Integer is
              (Board_X + (Board_Width * Cell_Size
                          - Integer (Tetris_Font.Text_Width (S, Scale))) / 2);
         begin
            Tetris_Font.Draw_Text (Rend, Centre ("PAUSED", 4), 340, 4, "PAUSED", Text);
            Tetris_Font.Draw_Text (Rend, Centre ("P TO RESUME", 2), 390, 2,
                                   "P TO RESUME", Muted);
         end;
      end if;
   end Draw;

end Tetris_Render;
