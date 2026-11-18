with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Tetris_Game; use Tetris_Game;

procedure Logic_Test is
   G : Game;
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; What : String) is
   begin
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("FAIL: " & What);
      else
         Put_Line ("ok:   " & What);
      end if;
   end Check;

   function In_Bounds_And_Free return Boolean is
      S : constant Shape_Grid := Shape (G.Current, G.Rotation);
      N : constant Positive := Piece_Size (G.Current);
   begin
      for R in 0 .. N - 1 loop
         for C in 0 .. N - 1 loop
            if S (R, C) then
               if G.X + C < 1 or else G.X + C > Board_Width
                 or else G.Y + R < 1 or else G.Y + R > Board_Rows
               then
                  return False;
               end if;
               if G.Board (G.Y + R, G.X + C) /= Empty then
                  return False;
               end if;
            end if;
         end loop;
      end loop;
      return True;
   end In_Bounds_And_Free;

   Old_Current : Piece_Kinds;
   Old_Next    : Piece_Kinds;
begin
   --  1. Fresh game.
   New_Game (G, 12345);
   Check (G.Status = Playing, "new game is playing");
   Check (G.Score = 0 and then G.Lines = 0 and then G.Level = 1, "fresh counters");
   Check (not G.Has_Hold, "hold starts empty");

   --  2. Ghost stops on the floor (O is 2 rows tall).
   G.Current := O;
   G.Rotation := 0;
   G.X := 5;
   G.Y := 1;
   Check (Ghost_Y (G) = Board_Rows - 1, "ghost lands on floor");

   --  3. Rotation near the right wall kicks instead of failing.
   New_Game (G, 999);
   G.Current := I;
   G.Rotation := 0;
   G.X := 7;             --  occupies columns 7 .. 10
   G.Y := 1;
   Rotate_CW (G);
   Check (G.Rotation = 1, "I rotates at the right wall");
   Check (In_Bounds_And_Free, "rotated I stays legal");

   --  4. Hold swaps the current piece with the first queued piece.
   New_Game (G, 777);
   Old_Current := G.Current;
   Old_Next := G.Next_Queue (1);
   Hold_Piece (G);
   Check (G.Has_Hold and then G.Hold_Kind = Old_Current, "hold stores current");
   Check (G.Current = Old_Next, "hold pulls from next queue");
   Check (G.Hold_Used, "hold is single-use");

   --  5. Line clear: fill row 24 except the last column, drop a vertical I there.
   New_Game (G, 4242);
   for C in 1 .. Board_Width - 1 loop
      G.Board (Board_Rows, C) := Z;
   end loop;

   G.Current := I;
   G.Rotation := 1;      --  vertical, occupies shape column 2
   G.X := 8;             --  shape column 2 => board column 10
   G.Y := 1;
   Check (G.Board (Board_Rows, Board_Width) = Empty, "hole is empty before drop");
   Hard_Drop (G);
   Check (G.Lines = 1, "single line counted");
   Check (G.Score >= 100, "line clear scored");

   Check (G.Board (Board_Rows, 1) = Empty, "cleared row is gone");
   Check (G.Board (Board_Rows, Board_Width) /= Empty, "rows above shifted down");

   if Failures = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line (Natural'Image (Failures) & " TEST(S) FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Logic_Test;
