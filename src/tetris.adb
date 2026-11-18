with Ada.Unchecked_Conversion;
with Interfaces; use Interfaces;
with Interfaces.C;
with SDL;
with SDL.Events;
with SDL.Events.Keyboards;
with SDL.Timers;
with SDL.Video;
with SDL.Video.Windows;
with SDL.Video.Windows.Makers;
with SDL.Video.Renderers;
with SDL.Video.Renderers.Makers;
--  SDL.Video.Windows bodies call exported helpers that live in this package
--  body, so it must be part of the link closure even though it is not called
--  directly here.
with SDL.Video.Surfaces.Makers;
pragma Elaborate (SDL.Video.Surfaces.Makers);

with Tetris_Game;
with Tetris_Render;

procedure Tetris is
   use type SDL.Timers.Milliseconds;
   use type SDL.Init_Flags;
   use type SDL.Video.Renderers.Renderer_Flags;
   use type Interfaces.C.int;
   use type Tetris_Game.Game_Status;

   function Seed_Now return Unsigned_32 is
     (Unsigned_32 (SDL.Timers.Milliseconds'(SDL.Timers.Ticks)));

   --  SDL_Event is a 56-byte union; only the type and keyboard payload are
   --  needed, so a plain byte-compatible overlay avoids the unfinished
   --  variant-record event abstraction in SDLAda.
   type Uint32_Array is array (Natural range <>) of Unsigned_32 with Convention => C;

   type Raw_Event is record
      Event_Type : Unsigned_32;
      Data       : Uint32_Array (0 .. 12);
   end record with Convention => C;

   type Keyboard_Event is record
      Event_Type : Unsigned_32;
      Time_Stamp : Unsigned_32;
      Window_ID  : Unsigned_32;
      State      : Unsigned_8;
      Repeat     : Unsigned_8;
      Pad_1      : Unsigned_8;
      Pad_2      : Unsigned_8;
      Scan_Code  : Interfaces.C.int;
      Key_Code   : Unsigned_32;
      Modifiers  : Unsigned_16;
      Pad_3      : Unsigned_16;
      Unused     : Unsigned_32;
      Pad_4      : Uint32_Array (0 .. 5);
   end record with Convention => C;

   function Poll_Event (E : out Raw_Event) return Interfaces.C.int with
     Import        => True,
     Convention    => C,
     External_Name => "SDL_PollEvent";

   function To_Keyboard is new Ada.Unchecked_Conversion (Raw_Event, Keyboard_Event);

   type Direction is (No_Direction, Left, Right);

   G              : Tetris_Game.Game;
   Running        : Boolean := True;
   Paused         : Boolean := False;
   Soft_Dropping  : Boolean := False;
   Das_Direction  : Direction := No_Direction;
   Das_Timer      : Natural := 0;
   Das_Delay_Done : Boolean := False;
   Last_Tick      : SDL.Timers.Milliseconds;
   Elapsed        : Natural;

   function Active return Boolean is
     (G.Status = Tetris_Game.Playing and then not Paused);

begin
   if not SDL.Initialise (SDL.Enable_Video or SDL.Enable_Events) then
      raise Program_Error with "SDL initialisation failed";
   end if;

   declare
      Win  : SDL.Video.Windows.Window;
      Rend : SDL.Video.Renderers.Renderer;
   begin
      SDL.Video.Windows.Makers.Create
        (Win, "Tetris - Ada + SDL2",
         SDL.Video.Windows.Centered_Window_Position,
         (Tetris_Render.Window_Width, Tetris_Render.Window_Height),
         SDL.Video.Windows.Shown);

      begin
         SDL.Video.Renderers.Makers.Create
           (Rend, Win,
            SDL.Video.Renderers.Accelerated or SDL.Video.Renderers.Present_V_Sync);
      exception
         when others =>
            SDL.Video.Renderers.Makers.Create
              (Rend, Win, SDL.Video.Renderers.Software);
      end;

      Tetris_Game.New_Game (G, Seed_Now);
      Last_Tick := SDL.Timers.Ticks;

      while Running loop
         declare
            Ev : Raw_Event;
         begin
            while Poll_Event (Ev) /= 0 loop
               if Ev.Event_Type = Unsigned_32 (SDL.Events.Quit) then
                  Running := False;

               elsif Ev.Event_Type = Unsigned_32 (SDL.Events.Keyboards.Key_Down)
                 or else Ev.Event_Type = Unsigned_32 (SDL.Events.Keyboards.Key_Up)
               then
                  declare
                     K   : constant Keyboard_Event := To_Keyboard (Ev);
                     Key : constant SDL.Events.Keyboards.Key_Codes :=
                       SDL.Events.Keyboards.Key_Codes (K.Key_Code);
                  begin
                     if K.State = 1 then
                        if K.Repeat = 0 then
                           case Key is
                              when SDL.Events.Keyboards.Code_Escape =>
                                 if G.Status = Tetris_Game.Game_Over then
                                    Running := False;
                                 else
                                    Paused := not Paused;
                                 end if;

                              when SDL.Events.Keyboards.Code_Q =>
                                 Running := False;

                              when SDL.Events.Keyboards.Code_R =>
                                 Tetris_Game.New_Game (G, Seed_Now);
                                 Paused := False;
                                 Soft_Dropping := False;
                                 Das_Direction := No_Direction;

                              when SDL.Events.Keyboards.Code_P =>
                                 if G.Status = Tetris_Game.Playing then
                                    Paused := not Paused;
                                 end if;

                              when SDL.Events.Keyboards.Code_Left =>
                                 if Active then
                                    Tetris_Game.Move_Left (G);
                                    Das_Direction := Left;
                                    Das_Timer := 0;
                                    Das_Delay_Done := False;
                                 end if;

                              when SDL.Events.Keyboards.Code_Right =>
                                 if Active then
                                    Tetris_Game.Move_Right (G);
                                    Das_Direction := Right;
                                    Das_Timer := 0;
                                    Das_Delay_Done := False;
                                 end if;

                              when SDL.Events.Keyboards.Code_Down =>
                                 if Active then
                                    Soft_Dropping := True;
                                 end if;

                              when SDL.Events.Keyboards.Code_Up | SDL.Events.Keyboards.Code_X =>
                                 if Active then
                                    Tetris_Game.Rotate_CW (G);
                                 end if;

                              when SDL.Events.Keyboards.Code_Z =>
                                 if Active then
                                    Tetris_Game.Rotate_CCW (G);
                                 end if;

                              when SDL.Events.Keyboards.Code_Space =>
                                 if Active then
                                    Tetris_Game.Hard_Drop (G);
                                 end if;

                              when SDL.Events.Keyboards.Code_C =>
                                 if Active then
                                    Tetris_Game.Hold_Piece (G);
                                 end if;

                              when others =>
                                 null;
                           end case;
                        end if;

                     else
                        case Key is
                           when SDL.Events.Keyboards.Code_Left =>
                              if Das_Direction = Left then
                                 Das_Direction := No_Direction;
                              end if;

                           when SDL.Events.Keyboards.Code_Right =>
                              if Das_Direction = Right then
                                 Das_Direction := No_Direction;
                              end if;

                           when SDL.Events.Keyboards.Code_Down =>
                              Soft_Dropping := False;

                           when others =>
                              null;
                        end case;
                     end if;
                  end;
               end if;
            end loop;
         end;

         declare
            Now : constant SDL.Timers.Milliseconds := SDL.Timers.Ticks;
         begin
            Elapsed := Natural (Now - Last_Tick);
            Last_Tick := Now;
         end;

         if Elapsed > 100 then
            Elapsed := 100;
         end if;

         if Active then
            if Das_Direction /= No_Direction then
               Das_Timer := Das_Timer + Elapsed;
               if not Das_Delay_Done and then Das_Timer >= 160 then
                  Das_Delay_Done := True;
                  Das_Timer := 0;
               end if;
               if Das_Delay_Done then
                  while Das_Timer >= 45 loop
                     Das_Timer := Das_Timer - 45;
                     if Das_Direction = Left then
                        Tetris_Game.Move_Left (G);
                     else
                        Tetris_Game.Move_Right (G);
                     end if;
                  end loop;
               end if;
            end if;

            Tetris_Game.Advance (G, Elapsed, Soft_Dropping);
         end if;

         Tetris_Render.Draw (Rend, G, Paused);
         Rend.Present;
         SDL.Timers.Wait_Delay (SDL.Timers.Milliseconds (1));
      end loop;
   end;

   SDL.Quit;
end Tetris;
