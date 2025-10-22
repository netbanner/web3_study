package main 

import "fmt"


func main(){
	strs :=[]string{"flower","flow","flight"}

	strs2 :=[]string{"dog","racecar","car"}
	fmt.Println("最长公共前缀：",longestCommonPrefix(strs))
	fmt.Println("最长公共前缀：",longestCommonPrefix(strs2))

}

func longestCommonPrefix(strs []string) string{
	count :=len(strs)
	if count==0{
		return ""
	}
	prefix :=strs[0]
	for i :=1;i<len(strs);i++ {
		prefix = lcp(prefix,strs[i])
		if len(prefix)==0{
			return ""
		}
	}
	return prefix
}

func lcp(str1 string,str2 string) string{
	 l1 :=len(str1)
	 l2 :=len(str2)
	  
	 if l1>l2 {
		l1 = l2
	 }

	 i :=0
	 for i<l1&&str1[i]==str2[i]{
		 i++
	 }

	 return str2[:i]

}