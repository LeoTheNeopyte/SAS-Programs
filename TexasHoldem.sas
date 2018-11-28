proc iml;

	*Specify number of hands;
	nHands=10;
	
	*create deck;
	rank={A,2,3,4,5,6,7,8,9,10,J,Q,K};
	suit={C D H S};
	
	*Clubs Dimonds Hearts Spades;
	deck=concat(right(repeat(rank,1,4)),repeat(suit,13,1));
	print deck;
	
	*Sample cards from deck;
	cards=sample(deck,(23//nhands),"WOR");
	
	*Combine 1st and 2nd card for each person into single cell;
	card1=cards[,1:9];
	card2=cards[,10:18];
	community=cards[,19:23];
	hands=concat(card1,",",card2) || community;
	
	*Create column names;
	do i=1 to 9;
		name=name || ("p"+strip(char(i)));
	end;
	
	name=name || {c1 c2 c3 c4 c5};
	print (hands[1:10,]) [colname=name];
	
	*Probability of pocket aces?;
	deck = repeat(rank,4);
	hands=10000;
	call randseed(802);
	
	*Sample many hands and count the number of pocet aces;
	count = 0;
	do i=1 to hands;
		sam = sample(deck,2,"WOR");
		aces= (sam[1]='A' & sam[2]='A');
		if aces=1 then do;
			count=count+1;
		end;
	end;
	
	*print results;
	p=count/hands;
	print count hands p;
quit;
		
	