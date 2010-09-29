example_nodes = {
  'a' => Proc.new do
    n = Chef::Node.new
    n.name 'a'
    n.run_list << "alpha"
    n.tag "apples"
    n.nested({:a1 => {
                 :a2 => {:a3 => "A1_A2_A3-a"},
                 :b2 => {:a3 => "A1_B2_A3-a"}
               },
               :b1 => {
                 :a2 => {:a3 => "B1_A2_A3-a"},
                 :b2 => {:a3 => "B1_B2_A3-a"}
               }
             })
    n.value 1
    n.multi_word "foo bar baz"
    n
  end,

  'b' => Proc.new do
    n = Chef::Node.new
    n.name 'b'
    n.run_list << "bravo"
    n.tag "apes"
    n.nested({:a1 => {
                 :a2 => {:a3 => "A1_A2_A3-b"},
                 :b2 => {:a3 => "A1_B2_A3-b"}
               },
               :b1 => {
                 :a2 => {:a3 => "B1_A2_A3-b"},
                 :b2 => {:a3 => "B1_B2_A3-b"}
               }
             })
    n.value 2
    n.multi_word "bar"
    n
  end,

  'ab' => Proc.new do
    n = Chef::Node.new
    n.name 'ab'
    n.run_list << "alpha"
    n.run_list << "bravo"
    n.tag "ack"
    n.multi_word "bar foo"
    n.quotes "\"one\" \"two\" \"three\""
    n
  end,

  'c' => Proc.new do
    n = Chef::Node.new
    n.name 'c'
    n.run_list << "charlie"
    n.tag "apes"
    n.nested({:a1 => {
                 :a2 => {:a3 => "A1_A2_A3-c"},
                 :b2 => {:a3 => "A1_B2_A3-c"}
               },
               :b1 => {
                 :a2 => {:a3 => "B1_A2_A3-c"},
                 :b2 => {:a3 => "B1_B2_A3-c"}
               }
             })
    n.value 3
    n.multi_word "foo"
    n
  end
}

example_nodes.each do |name, nproc|
  n = nproc.call
  n.save
  puts "saved node: #{name}"
end
