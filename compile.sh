#!/bin/sh

./xm2qed68
if [ $? = 0 ]; then
	tprbuilder qed68.tpr
	rm qed68.89z
	rm qed68.v2z
fi