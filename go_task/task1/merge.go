package main


import (
	"fmt" 
	"sort"
)

func merge(intervals [][]int) [][]int {
	res :=[][]int{}
	if intervals == nil || len(intervals)==0 {
        return res
    }

	sort.Slice(intervals, func(i, j int) bool {
		return intervals[i][0] < intervals[j][0]
	})
	 

	pre :=intervals[0]

	for i:=1;i<len(intervals);i++{
		cur :=intervals[i]
		if (pre[1]<cur[0]){
			res = append(res,pre)
			pre = cur
		}else{
			pre[1] = max(pre[1],cur[1])
		}
	}
	res = append(res,pre)
	return res
}

func max(a,b int) int {
	if a>b{
	 return a
	}
     return b
}

func main(){
	intervals:= [][]int{{1,3},{2,6},{8,10},{15,18}}

	fmt.Println("合并区间：",merge(intervals))

	intervals2:= [][]int{{1,4},{4,6}}

	fmt.Println("合并区间2：",merge(intervals2))

}