-module(servidor).
-export([server/0]).

server() ->	
	io:format("Server On ~n ", []),
	Frames = spawn(fun() -> frames() end),
	Gestor_Logins = spawn(fun() -> gestor_logins(#{}) end),
	Gestor_Bolas  = spawn(fun() -> gestor_Bolas(#{}) end),
	Room = spawn(fun() -> room([]) end),
	Gestor_Bolas ! {new_planeta, "Planeta1", self()},
	Gestor_Bolas ! {new_planeta, "Planeta2", self()},
	Gestor_Bolas ! {new_planeta, "Planeta3", self()},
	Gestor_Bolas ! {new_planeta, "Planeta4", self()},
	Gestor_Bolas ! {new_planeta, "Planeta5", self()},
	Gestor_Bolas ! {new_planeta, "Planeta6", self()},
	Gestor_Bolas ! {new_planeta, "Planeta7", self()},
	Gestor_Bolas ! {new_avatar, "User1", self()},
	{ok, LSock} = gen_tcp:listen(12345, [list, {packet, line}, {reuseaddr, true}]),
	acceptor(LSock,Gestor_Bolas, Gestor_Logins,Frames,Room).


acceptor(LSock,Gestor_Bolas, Gestor_Logins,Frames,Room) ->
	{ok, Sock} = gen_tcp:accept(LSock),
	spawn(fun() -> acceptor(LSock,Gestor_Bolas, Gestor_Logins,Frames,Room) end),
	Room ! {entra,self()},
						 % Username
	user(Sock,Gestor_Bolas,"",Gestor_Logins,Frames, Room).


room(Pids) -> % Rooms mapa de salas
	receive
		{entra, Pid} ->
			io:format("user entered ~n ", []),
			room([Pid | Pids]);
		{line, Data, User,Gestor_Bolas, Gestor_Logins,Frames, Room, Pid} ->
			%Data2 = string:strip(Data,both,$\n),
			%RegExp = "Username: [a-zA-Z]*[0-9]*", % para podermos ter por exemplo User2, User2, uSer1, uSer3
			Data1 = string:strip(Data, both, $\n),
			%Data2 = string:strip(Data2, both, $\r),
			%io:format("~p ~n   ", [Data1]),
			%io:format("~p ~n   ", [Data1]),
			case Data1 of
				"1" ++ _ ->
					%io:format("ola1~n   ", []),
					L = string:tokens(Data1," "),
					%User = lists:nth(2,L),
					%Pass = lists:nth(3,L),
					%io:format("~p ~n   ", [User]),
					Gestor_Logins ! {login, lists:nth(2,L), lists:nth(3,L),Gestor_Bolas,Frames, Room, Pid},
					room(Pids);	
				"2" ++ _ ->
					L = string:tokens(Data1," "),
					%User = lists:nth(2,L),
					%Pass = lists:nth(3,L),
					%io:format("~p ~n   ", [[lists:nth(2,L)]]),
					%io:format("Pedido de Login ~p ~n", [Pid]),
					Gestor_Logins ! {new_user, lists:nth(2,L), lists:nth(3,L),Gestor_Bolas, Pid},
					io:format("Ja mandei para o gestor de logins~n   ", []),
					room(Pids);
				"4" ++ _ ->
					L = string:tokens(Data1," "),
					%User = lists:nth(2,L),
					%Pass = lists:nth(3,L),
					%io:format("~p ~n   ", [lists:nth(2,L)]),
					%io:format("Pedido de Login ~p ~n", [Pid]),
					Gestor_Logins ! {logout, lists:nth(2,L), Pid},
					io:format("Logout con sucesso~n   ", []),
				room(Pids);
				"UP" ->
					%io:format("~p ~n",[Data2]),
					Gestor_Bolas ! {faster, "User1"};
				"RIGHT" ->
					%io:format("~p ~n",[Data2]),
					Gestor_Bolas ! {turn_right, "User1"};
				"LEFT" ->
					Gestor_Bolas ! {turn_left, "User1"};
				"DOWN" ->
					%io:format("~p ~n",[Data2]),
					Gestor_Bolas ! {slower, "User1"}
			end,
			%Msg = "ola",
			%[Pid ! {line,Msg} || Pid <- Pids],
			room(Pids);
		{line, Data} = Msg ->
			%io:format("received ~p ~n   ", [Data]),
			[Pid ! {line,Msg,Pid} || Pid <- Pids],
			room(Pids);
		{sai, Pid} ->
			io:format("user left ~n ", []),
			room(Pids -- [Pid]) % remove da lista dos jogadores o jogador com process id = Pid
		end.



user(Sock,Gestor_Bolas, Username, Gestor_Logins,Frames, Room) ->
	receive
		{line, Data,_} ->
			%io:format("~p ~n", [Data]),
			gen_tcp:send(Sock, Data),
			user(Sock,Gestor_Bolas, Username, Gestor_Logins,Frames,Room);
		{tcp, _, Data} ->
						   %{line, Data, Username, Sala, Gestor_Contas, Gestor_Salas, Gestor_Bolas, Pid}
			Room ! {line, Data,Username,Gestor_Bolas, Gestor_Logins,Frames, Room,self()},
			user(Sock,Gestor_Bolas, Username, Gestor_Logins,Frames,Room);
		
		% mensagens do gestor de logins
		{loginOK, New_User} ->
			user(Sock,Gestor_Bolas, New_User, Gestor_Logins,Frames,Room);
		{logoutOK, _} -> % {logoutOK, Pid} 
			user(Sock,Gestor_Bolas, "", Gestor_Logins,Frames,Room);
		%%%%%

		{tcp_closed, _} ->
			Room ! {sai, self()};
		{tcp_error, _, _} ->
			Room ! {sai, self()}
end.



gestor_logins(Users) -> 
	receive
		{new_user, Username, Password, Gestor_Bolas, Pid} ->
			io:format("Vou tentar criar um novo user~n",[]),
			Find = maps:find(Username,Users), % Returns a tuple {ok, Value}, where Value is the value associated with Key, or error if no value is associated with Key in Map.
			case Find of
				{ok,_} ->
					%io:format("Esta conta ja existe ~n",[]),
					Pid ! {line, "Error: Username already taken\n",Pid},
					gestor_logins(Users);
				error ->
					io:format("Novo user com sucesso~n",[]),
					%io:format("Vamos registar o utilizador ~n",[]),
					New_Users = maps:put(Username,{out,Password},Users), % out significa que o utiliador nao tem login feito
					Pid ! {line, "Congratulations you are now a Gravity player!\n",Pid},
					Gestor_Bolas ! {new_avatar, Username, self()},
					gestor_logins(New_Users)
			end;
		{login, Username, Password, Gestor_Bolas,Frames, Room, Pid} ->
			Find = maps:find(Username,Users),
			%io:format("Login ~n",[]),
			case Find of
				{ok,{out,Pass1}} ->
					if
						Pass1 == Password -> 
							%io:format("Login efetuado com sucesso ~n",[]),
							New_Login = maps:update(Username,{in,Password},Users), % in significa que o utilizador tem login feito
							%io:format("Login successfully  ~n",[]),
							Pid ! {loginOK, Username},
							Pid ! {line,"Welcome back!\n",Pid},
							Gestor_Bolas ! {start_game, Frames, Room},
							io:format("Welcome back! ~n",[]),
							gestor_logins(New_Login);
						true -> % else
							io:format("Error: Password don't match ~n",[]),
							Pid ! {line, "Error: Password don't match\n",Pid},
							gestor_logins(Users)
					end;
				{ok,{in,_}} ->
					Pid ! {line, "Error: Already in\n",Pid},
					gestor_logins(Users);
				error ->
					Pid ! {line, "Error: No matching account\n",Pid},
					gestor_logins(Users)
			end;
		{logout, Username, Pid} ->
			Find = maps:find(Username,Users),
			case Find of
				{ok, {_,Password}} ->
					Pid ! {logoutOK, Pid},
					Logout = maps:update(Username,{out,Password},Users),
					Pid ! {line, "Logout com sucesso\n",Pid},
					gestor_logins(Logout);
				error ->
					gestor_logins(Users)
			end
	end.

gestor_Bolas(Bolas) ->
	receive
		{new_avatar, Nome, Pid} ->
			%"Avatar Raio " ++ _ -> % se for avatar por exemplo: "Avatar Raio 20"
			%Lista        = string:tokens(Nome," "),
			%Raio,_}     = string:to_integer(lists:last(Lista)),
			Score        = 0,
			Alpha        = 0.0, 
    		Fuel         = 500,
    		Ratio        = 1,
			LocX         = 720/2,
			LocY         = 720/2,
			CorR         = rand:uniform(255),
			CorG         = rand:uniform(255),
			CorB         = rand:uniform(255),
			Velocity_x   = 0,
			Velocity_y   = 0,
			Raio         = 15,
						%{"Planeta1" =>   {139 ,687  ,68   ,60  ,157 ,50   ,0          ,0.5        ,0     ,0    ,0     ,0    ,<0.387.0>}
			New_MapBolas = maps:put(Nome,{LocX, LocY, CorR,CorG,CorB, Raio, Velocity_x, Velocity_y, Alpha, Fuel, Ratio,Score, Pid}, Bolas),
			%io:format("Parabens já tens o teu proprio avatar~n",[]),
			gestor_Bolas(New_MapBolas);

		{new_planeta, Nome, Pid} ->
    		X          = rand:uniform(720),
 			Y          = rand:uniform(720),
 			CorR       = rand:uniform(255),
 			CorG       = rand:uniform(255),
 			CorB       = rand:uniform(255),
 			Raio       = rand:uniform(100),
 			%LocX       = random(Raio,720-Raio), ???????
			%LocY       = random(Raio,720-Raio), ???????
			Vel        = rand:uniform(1),
 			Velocity_x = Vel,
 			Velocity_y = Vel,
			%if
			%	is_key(Nome) == false ->
					New_MapBolas = maps:put(Nome,{X, Y, CorR,CorG,CorB, Raio, Velocity_x, Velocity_y, 0,0,0,0, Pid}, Bolas),
			%	true ->
			%		io:format("Planeta ja existe ~n",[]),
			%	
			%end,
			gestor_Bolas(New_MapBolas);
		{turn_right, User} ->
			{ok,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, Alpha, Fuel, Ratio,Score, Pid}} = maps:find(User,Bolas),
			%io:format("RIGHT_B ~n",[]),
			New_Alpha = Alpha + 0.2,
			New_Fuel = Fuel-1,
			New_MapBolas = maps:update(User,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, New_Alpha, New_Fuel, Ratio,Score, Pid},Bolas),
			gestor_Bolas(New_MapBolas);
		{turn_left, User} ->
			{ok,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, Alpha, Fuel, Ratio,Score, Pid}} = maps:find(User,Bolas),
			%io:format("LEFT_B ~n",[]),
			New_Alpha = Alpha - 0.2,
			New_Fuel = Fuel-1,
			New_MapBolas = maps:update(User,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, New_Alpha, New_Fuel, Ratio,Score, Pid},Bolas),
			gestor_Bolas(New_MapBolas);
		{faster,User} ->
			{ok,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, Alpha, Fuel, Ratio,Score, Pid}} = maps:find(User,Bolas),
			%io:format("FAST - FUEL - ~p ~n",[Fuel]),
			New_Ratio = Ratio,
			New_Fuel = Fuel,
			%if
			%	Fuel > 0 ->
			%		New_Ratio = Ratio + 1
			%		if New_Ratio > 0 ->
			%			New_Fuel = Fuel-1
			%		end
			%end,
			New_MapBolas = maps:update(User,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, Alpha, New_Fuel, New_Ratio,Score, Pid},Bolas),
			gestor_Bolas(New_MapBolas);
		{slower,User} ->
			{ok,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, Alpha, Fuel, Ratio,Score, Pid}} = maps:find(User,Bolas),
			%io:format("SLOW_B ~n",[]),
			New_Ratio = Ratio,
			New_Fuel = Fuel,
			%if
			%	Fuel > 0 ->
			%		New_Ratio = Ratio - 1,
			%		if 
			%			New_Ratio > 0 ->
			%				New_Fuel = Fuel-1;
			%			true ->
			%				New_Fuel = Fuel
			%		end;
			%	true ->
			%		New_Ratio = Ratio
			%end,
			New_MapBolas = maps:update(User,{LocX, LocY, CorR,CorG,CorB,Raio, Velocity_x, Velocity_y, Alpha, New_Fuel, New_Ratio,Score, Pid},Bolas),
			gestor_Bolas(New_MapBolas);
		

		{start_game, Frames, Room} ->
			%io:format("Start Game~n",[]),
		%   Nome,{LocX, LocY, CorR,CorG,CorB, Velocity_x, Velocity_y, Alpha, Fuel, Ratio, Pid}
			CheckLimite = maps:fold(fun(K,{LocX, LocY, CorR,CorG,CorB, Raio, Velocity_x, Velocity_y, Alpha, Fuel, Ratio,Score, Pid},BolasAcc) ->
				%{New_LocX,New_LocY,New_Velocity_x,New_Velocity_y} = {0,0,0,0},
				case K of
					"Planeta" ++ _ ->
						if
							LocX > (720-Raio) ->
								New_LocX       = 720-Raio,
								New_LocY       = LocY,
								New_Velocity_x = -Velocity_x,
								New_Velocity_y = Velocity_y;
							Raio >= LocX ->
								New_LocX       = Raio,
								New_LocX       = LocX,
								New_LocY       = LocY,
								New_Velocity_x = -Velocity_x,
								New_Velocity_y = Velocity_y;
							LocY > (720-Raio) ->
								New_LocX       = LocX,
								New_LocY       = 720-Raio,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = -Velocity_y;
							true ->
								New_LocX       = LocX,
								New_LocY       = LocY,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = Velocity_y
						end;
					K ->
						if  
							LocX > (720+Raio-2) ->
								New_LocX       = -Raio-2,
								New_LocY       = LocY,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = Velocity_y;
							LocY > (720+Raio-2) ->
								New_LocX       = LocX,
								New_LocY       = -Raio-2,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = Velocity_y;	
							LocX < (-(Raio+2)) andalso Velocity_x < 0 ->
								New_LocX       = 720,
								New_LocY       = LocY,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = Velocity_y;	
							LocY < (-(Raio+2)) andalso Velocity_y < 0 ->
								New_LocX       = LocX,
								New_LocY       = 720,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = Velocity_y;
							true ->
								New_LocX       = LocX,
								New_LocY       = LocY,
								New_Velocity_x = Velocity_x,
								New_Velocity_y = Velocity_y		
						end
				end,
				maps:put(K,{New_LocX, New_LocY, CorR,CorG,CorB, Raio, New_Velocity_x, New_Velocity_y, Alpha, Fuel, Ratio,Score, Pid},BolasAcc)
			end,#{},Bolas),

			NewPosition = maps:fold(fun(K2, {LocX2, LocY2, CorR2,CorG2,CorB2, Raio2, Velocity_x2, Velocity_y2, Alpha2, Fuel2, Ratio2,Score2, Pid2}, Acumulador) ->
				%New_LocX = LocX+Velocity_x,
				%New_LocY = LocY+Velocity_y,
				%io:format("LocX --> ~p  ||| New_LocX --> ~p ~n",[LocX2,LocX2+Velocity_x2]),
				%io:format("LocY --> ~p  ||| New_LocY --> ~p ~n",[LocY2,LocY2+Velocity_y2]),
				maps:put(K2,{LocX2+Velocity_x2, LocY2+Velocity_y2, CorR2,CorG2,CorB2, Raio2, Velocity_x2, Velocity_y2, Alpha2, Fuel2, Ratio2,Score2, Pid2},Acumulador)
			end,#{},CheckLimite),

			NovasCoordenadas_str = maps:fold(fun(K3, {LocX3, LocY3, CorR3,CorG3,CorB3, Raio3, Velocity_x3, Velocity_y3, Alpha3, Fuel3, Ratio3,Score3, Pid3}, Acumulador_str) ->
				lists:concat([Acumulador_str,K3,'@',LocX3,'@', LocY3,'@', CorR3,'@',CorG3,'@',CorB3,'@', Raio3,'@', Velocity_x3,'@', Velocity_y3,'@', Alpha3,'@', Fuel3,'@', Ratio3,'@',Score3, '\n'])
				%io:format("~p#~p#~p#~p#~p#~p#~p#~p#~p#~p#~p#~p#~p#~p ~n",[K3, LocX3, LocY3, CorR3,CorG3,CorB3, Raio3, Velocity_x3, Velocity_y3, Alpha3, Fuel3, Ratio3,Score3, Pid3])
			end, "", NewPosition),
			

			maps:fold(fun(K4, {_,_,_,_,_,_,_,_,_,_,_,_,Pid4}, _) ->
					Pid4 ! {line, NovasCoordenadas_str,Pid4}
					%io:format("~p ~n",[NovasCoordenadas_str])
				end, true, Bolas),
			Frames ! {frame, self(), Room},
			gestor_Bolas(NewPosition)
	end.




frames() ->
	receive
		{frame, Gestor_Bolas, Room} ->
			timer:sleep(16), % para recalcular +-60 vezes num segundo, assim conseguidos fazer 60 frames por segundo
			Gestor_Bolas ! {start_game,self(), Room},
			frames()
	end.




